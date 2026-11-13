using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BigFit.Application.Abstractions;
using BigFit.Application.Notifications;
using BigFit.Application.Payments;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BigFit.Infrastructure.Payments;

internal sealed class SePayPaymentService(
    BigFitDbContext dbContext,
    INotificationService notifications,
    IConfiguration configuration,
    IHttpClientFactory httpClientFactory,
    ILogger<SePayPaymentService> logger) : IPaymentService
{
    private const string CodProvider = "Cod";
    private const string SePayProvider = "SePay";
    private const string CodMethod = "cod";
    private const string BankMethod = "bankTransfer";
    private const string GatewayMethod = "gateway";
    private static readonly SemaphoreSlim TokenLock = new(1, 1);
    private static string? CachedToken;
    private static DateTimeOffset TokenExpiresAt;

    public async Task<PaymentSessionResponse> CreateAsync(
        Guid userId,
        Guid orderId,
        string method,
        CancellationToken cancellationToken)
    {
        if (method is not (CodMethod or BankMethod or GatewayMethod))
        {
            throw new ArgumentException(ApiMessages.UnsupportedPaymentMethod, nameof(method));
        }

        var order = await dbContext.Orders.SingleOrDefaultAsync(
            item => item.Id == orderId && item.UserId == userId,
            cancellationToken);
        if (order is null || order.Status != "Pending")
        {
            throw new ArgumentException(ApiMessages.OrderNotPayable, nameof(orderId));
        }

        if (await dbContext.Payments.AnyAsync(
                payment => payment.OrderId == order.Id && payment.Status == "Succeeded",
                cancellationToken))
        {
            throw new DataConflictException(ApiMessages.PaymentAlreadyCompleted);
        }

        var now = DateTimeOffset.UtcNow;
        if (method == CodMethod)
        {
            var cod = await LatestAsync(order.Id, CodProvider, cancellationToken);
            if (cod is null || cod.Status is not "Pending")
            {
                cod = new Payment
                {
                    OrderId = order.Id,
                    Provider = CodProvider,
                    Method = CodMethod,
                    Status = "Pending",
                    Amount = order.TotalAmount,
                    CurrencyCode = order.CurrencyCode
                };
                dbContext.Payments.Add(cod);
            }

            await CancelOtherPendingAsync(order.Id, cod.Id, cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);
            return Map(cod, null, null);
        }

        var settings = ReadSettings();
        var account = await LoadLinkedAccountAsync(settings, cancellationToken);
        var amount = ToVnd(order, settings.EurToVndRate);
        var payment = await LatestAsync(order.Id, SePayProvider, cancellationToken);
        if (payment is null)
        {
            payment = new Payment
            {
                OrderId = order.Id,
                Provider = SePayProvider,
                Method = method,
                Status = "Pending",
                Amount = amount,
                CurrencyCode = "VND"
            };
            dbContext.Payments.Add(payment);
        }
        else
        {
            payment.Method = method;
            payment.Status = "Pending";
            payment.Amount = amount;
            payment.CurrencyCode = "VND";
            payment.ProviderReference = null;
            payment.CompletedAt = null;
            payment.CreatedAt = now;
        }

        await CancelOtherPendingAsync(order.Id, payment.Id, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(payment, null, TransferFields(order, payment, account));
    }

    public async Task<PaymentSessionResponse> SimulateSandboxPaymentAsync(
        Guid userId,
        Guid orderId,
        Guid paymentId,
        CancellationToken cancellationToken)
    {
        var order = await dbContext.Orders.AsNoTracking().SingleOrDefaultAsync(
            item => item.Id == orderId && item.UserId == userId,
            cancellationToken);
        var payment = order is null
            ? null
            : await dbContext.Payments.AsNoTracking().SingleOrDefaultAsync(
                item => item.Id == paymentId && item.OrderId == order.Id && item.Provider == SePayProvider,
                cancellationToken);
        if (order is null || payment is null)
        {
            throw new ArgumentException(ApiMessages.PaymentNotFound, nameof(paymentId));
        }

        if (payment.Status == "Succeeded")
        {
            return Map(payment, null, TransferFields(order, payment, null));
        }
        if (payment.Status != "Pending")
        {
            throw new DataConflictException(ApiMessages.PaymentAttemptNotPending);
        }

        var settings = ReadSettings();
        var account = await LoadLinkedAccountAsync(settings, cancellationToken);
        var token = await AccessTokenAsync(settings, cancellationToken);
        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{settings.ApiBaseUrl}/v1/transaction/create")
        {
            Content = JsonContent.Create(new
            {
                bank_account_xid = account.Xid,
                transfer_type = "credit",
                amount = (long)decimal.Round(payment.Amount, 0, MidpointRounding.AwayFromZero),
                transaction_content = order.OrderNumber
            })
        };
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        using var response = await httpClientFactory.CreateClient(nameof(SePayPaymentService))
            .SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "Bank Hub sandbox transaction create failed with status {StatusCode}.",
                (int)response.StatusCode);
            throw new ArgumentException(ApiMessages.SandboxSimulationFailed);
        }

        var transactionId = await ReadTransactionIdAsync(response, cancellationToken);
        if (string.IsNullOrWhiteSpace(transactionId))
        {
            logger.LogWarning("Bank Hub sandbox transaction create returned no transaction id.");
            throw new ArgumentException(ApiMessages.SandboxSimulationFailed);
        }

        var trackedOrder = await dbContext.Orders.SingleAsync(
            item => item.Id == order.Id, cancellationToken);
        var trackedPayment = await dbContext.Payments.SingleAsync(
            item => item.Id == payment.Id, cancellationToken);
        if (trackedPayment.Status != "Pending")
        {
            throw new DataConflictException(ApiMessages.PaymentAttemptNotPending);
        }
        await MarkTransferSucceededAsync(trackedOrder, trackedPayment, transactionId, cancellationToken);
        return Map(trackedPayment, null, TransferFields(trackedOrder, trackedPayment, account));
    }

    public async Task<SepayBankAccountResponse> GetLinkedBankAccountAsync(
        CancellationToken cancellationToken)
    {
        var account = await LoadLinkedAccountAsync(ReadSettings(), cancellationToken);
        return new SepayBankAccountResponse(
            account.BankCode,
            account.BankBin,
            account.AccountNumber,
            account.AccountHolderName);
    }

    public async Task<PaymentSessionResponse?> GetLatestAsync(
        Guid userId,
        Guid orderId,
        CancellationToken cancellationToken)
    {
        var owned = await dbContext.Orders.AsNoTracking().AnyAsync(
            order => order.Id == orderId && order.UserId == userId,
            cancellationToken);
        if (!owned)
        {
            return null;
        }

        var payment = await dbContext.Payments.AsNoTracking()
            .Where(item => item.OrderId == orderId)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        return payment is null ? null : Map(payment, null, null);
    }

    public async Task<PaymentSessionResponse> ReportClientResultAsync(
        Guid userId,
        Guid orderId,
        Guid paymentId,
        string result,
        CancellationToken cancellationToken)
    {
        if (result is not ("cancel" or "error"))
        {
            throw new ArgumentException(ApiMessages.UnsupportedPaymentResult, nameof(result));
        }

        var order = await dbContext.Orders.SingleOrDefaultAsync(
            item => item.Id == orderId && item.UserId == userId,
            cancellationToken);
        var payment = order is null
            ? null
            : await dbContext.Payments.SingleOrDefaultAsync(
                item => item.Id == paymentId && item.OrderId == order.Id,
                cancellationToken);
        if (order is null || payment is null)
        {
            throw new ArgumentException(ApiMessages.PaymentNotFound, nameof(paymentId));
        }

        if (payment.Status == "Pending")
        {
            payment.Status = result == "cancel" ? "Cancelled" : "Failed";
            payment.CompletedAt = DateTimeOffset.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
            await NotifyAsync(
                order,
                payment,
                ApiMessages.PaymentNotCompletedTitle,
                result == "cancel"
                    ? ApiMessages.PaymentCancelledMessage(order.OrderNumber)
                    : ApiMessages.PaymentFailedMessage(order.OrderNumber),
                cancellationToken);
            logger.LogInformation(
                ApiMessages.SePayPaymentUpdatedLog,
                payment.Id,
                order.OrderNumber,
                payment.Status);
        }

        return Map(payment, null, null);
    }

    public async Task<bool> HandleIpnAsync(
        string? secretKey,
        SepayIpnPayload payload,
        CancellationToken cancellationToken)
    {
        var expected = configuration["Payments:SePay:IpnSecretKey"];
        if (string.IsNullOrWhiteSpace(expected) || !SecretsMatch(secretKey, expected))
        {
            return false;
        }

        if (IsBankHub(payload))
        {
            await ApplyBankHubAsync(payload, cancellationToken);
            return true;
        }

        var invoice = payload.Order?.OrderInvoiceNumber;
        if (string.IsNullOrWhiteSpace(invoice) || string.IsNullOrWhiteSpace(payload.NotificationType))
        {
            return true;
        }

        var order = await dbContext.Orders.SingleOrDefaultAsync(
            item => item.OrderNumber == invoice,
            cancellationToken);
        if (order is null)
        {
            return true;
        }

        var payments = await dbContext.Payments
            .Where(item => item.OrderId == order.Id && item.Provider == SePayProvider)
            .OrderByDescending(item => item.CreatedAt)
            .ToListAsync(cancellationToken);
        var reference = ReadReference(payload.Transaction);
        var matched = payments.FirstOrDefault(item =>
            reference is not null && item.ProviderReference == reference);
        if (matched is not null && payload.NotificationType == "ORDER_PAID" && matched.Status == "Succeeded")
        {
            return true;
        }

        if (payload.NotificationType == "ORDER_PAID")
        {
            await ApplyPaidAsync(order, payments, payload, reference, cancellationToken);
        }
        else if (payload.NotificationType == "TRANSACTION_VOID")
        {
            await ApplyVoidAsync(order, payments, reference, cancellationToken);
        }

        return true;
    }

    private async Task ApplyPaidAsync(
        CustomerOrder order,
        List<Payment> payments,
        SepayIpnPayload payload,
        string? reference,
        CancellationToken cancellationToken)
    {
        if (payload.Order?.OrderCurrency is { Length: > 0 } currency &&
            !currency.Equals("VND", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var payment = payments.FirstOrDefault(item => item.Status == "Pending")
            ?? payments.FirstOrDefault(item => item.Status is "Failed" or "Cancelled")
            ?? payments.FirstOrDefault();
        if (payment is null || payment.Status == "Succeeded")
        {
            return;
        }

        var received = payload.Order?.OrderAmount
            ?? payload.Transaction?.TransactionAmount;
        if (!AmountMatches(payment.Amount, received))
        {
            logger.LogWarning(
                ApiMessages.SePayAmountMismatchLog,
                order.OrderNumber,
                payment.Amount,
                received);
            return;
        }

        var now = DateTimeOffset.UtcNow;
        payment.Status = "Succeeded";
        payment.ProviderReference = reference;
        payment.CompletedAt = now;
        order.Status = "Confirmed";
        order.UpdatedAt = now;
        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAsync(
            order,
            payment,
            ApiMessages.PaymentReceivedTitle,
            ApiMessages.PaymentReceivedMessage(order.OrderNumber),
            cancellationToken);
        logger.LogInformation(
            ApiMessages.SePayPaymentUpdatedLog,
            payment.Id,
            order.OrderNumber,
            payment.Status);
    }

    private async Task ApplyVoidAsync(
        CustomerOrder order,
        List<Payment> payments,
        string? reference,
        CancellationToken cancellationToken)
    {
        var payment = payments.FirstOrDefault(item =>
                reference is not null && item.ProviderReference == reference)
            ?? payments.FirstOrDefault(item => item.Status is "Pending" or "Succeeded");
        if (payment is null || payment.Status is "Cancelled" or "Failed" or "Refunded")
        {
            return;
        }

        var now = DateTimeOffset.UtcNow;
        payment.Status = "Cancelled";
        payment.ProviderReference ??= reference;
        payment.CompletedAt = now;
        if (order.Status == "Confirmed")
        {
            order.Status = "Pending";
            order.UpdatedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAsync(
            order,
            payment,
            ApiMessages.PaymentNotCompletedTitle,
            ApiMessages.PaymentCancelledMessage(order.OrderNumber),
            cancellationToken);
        logger.LogInformation(
            ApiMessages.SePayPaymentUpdatedLog,
            payment.Id,
            order.OrderNumber,
            payment.Status);
    }

    private static Dictionary<string, string> TransferFields(
        CustomerOrder order,
        Payment payment,
        LinkedBankAccount? account)
    {
        var fields = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["transferContent"] = order.OrderNumber,
            ["amount"] = payment.Amount.ToString("0", CultureInfo.InvariantCulture),
            ["currency"] = payment.CurrencyCode
        };
        if (account is null)
        {
            return fields;
        }

        fields["bankCode"] = account.BankCode;
        fields["bankBin"] = account.BankBin;
        fields["accountNumber"] = account.AccountNumber;
        fields["accountHolderName"] = account.AccountHolderName;
        return fields;
    }

    private async Task ApplyBankHubAsync(SepayIpnPayload payload, CancellationToken cancellationToken)
    {
        if (!string.Equals(payload.TransferType, "credit", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var reference = TrimReference(payload.TransactionId);

        if (!string.IsNullOrWhiteSpace(reference) &&
            await dbContext.Payments.AnyAsync(
                item => item.Provider == SePayProvider &&
                    item.ProviderReference == reference &&
                    item.Status == "Succeeded",
                cancellationToken))
        {
            return;
        }

        var order = await FindOrderAsync(payload, cancellationToken);
        if (order is null)
        {
            return;
        }

        var payments = await dbContext.Payments
            .Where(item => item.OrderId == order.Id && item.Provider == SePayProvider)
            .OrderByDescending(item => item.CreatedAt)
            .ToListAsync(cancellationToken);
        var payment = payments.FirstOrDefault(item => item.Status == "Pending")
            ?? payments.FirstOrDefault(item => item.Status is "Failed" or "Cancelled");
        if (payment is null || payment.Status == "Succeeded")
        {
            return;
        }

        var received = payload.Amount;
        if (!AmountMatches(payment.Amount, received))
        {
            logger.LogWarning(
                ApiMessages.SePayAmountMismatchLog,
                order.OrderNumber,
                payment.Amount,
                received);
            return;
        }

        await MarkTransferSucceededAsync(order, payment, reference, cancellationToken);
    }

    private async Task MarkTransferSucceededAsync(
        CustomerOrder order,
        Payment payment,
        string? reference,
        CancellationToken cancellationToken)
    {
        if (payment.Status == "Succeeded")
        {
            return;
        }

        reference = TrimReference(reference);
        if (!string.IsNullOrWhiteSpace(reference) &&
            await dbContext.Payments.AnyAsync(
                item => item.Id != payment.Id &&
                    item.Provider == SePayProvider &&
                    item.ProviderReference == reference &&
                    item.Status == "Succeeded",
                cancellationToken))
        {
            return;
        }

        var now = DateTimeOffset.UtcNow;
        payment.Status = "Succeeded";
        payment.ProviderReference = reference;
        payment.CompletedAt = now;
        order.Status = "Confirmed";
        order.UpdatedAt = now;
        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAsync(
            order,
            payment,
            ApiMessages.PaymentReceivedTitle,
            ApiMessages.PaymentReceivedMessage(order.OrderNumber),
            cancellationToken);
        logger.LogInformation(
            ApiMessages.SePayPaymentUpdatedLog,
            payment.Id,
            order.OrderNumber,
            payment.Status);
    }

    private async Task<CustomerOrder?> FindOrderAsync(
        SepayIpnPayload payload,
        CancellationToken cancellationToken)
    {
        var paymentCode = payload.PaymentCode?.Trim();
        if (!string.IsNullOrWhiteSpace(paymentCode))
        {
            var byCode = await dbContext.Orders.SingleOrDefaultAsync(
                item => item.OrderNumber == paymentCode &&
                    (item.Status == "Pending" || item.Status == "Confirmed"),
                cancellationToken);
            if (byCode is not null)
            {
                return byCode;
            }
        }

        var content = payload.Content?.Trim();
        if (string.IsNullOrWhiteSpace(content))
        {
            return null;
        }

        return await dbContext.Orders.SingleOrDefaultAsync(
            item => item.OrderNumber == content &&
                (item.Status == "Pending" || item.Status == "Confirmed"),
            cancellationToken);
    }

    private async Task<LinkedBankAccount> LoadLinkedAccountAsync(
        SePaySettings settings,
        CancellationToken cancellationToken)
    {
        var token = await AccessTokenAsync(settings, cancellationToken);
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"{settings.ApiBaseUrl}/v1/bank-account?page=1&per_page=20");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        using var response = await httpClientFactory.CreateClient(nameof(SePayPaymentService))
            .SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new ArgumentException(ApiMessages.BankAccountNotLinked);
        }

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
        LinkedBankAccount? configured = null;
        LinkedBankAccount? first = null;
        if (document.RootElement.TryGetProperty("data", out var data) &&
            data.ValueKind == JsonValueKind.Array)
        {
            foreach (var account in data.EnumerateArray())
            {
                var mapped = MapAccount(account);
                if (mapped is null)
                {
                    continue;
                }

                first ??= mapped;
                if (!string.IsNullOrWhiteSpace(settings.BankAccountXid) &&
                    string.Equals(mapped.Xid, settings.BankAccountXid, StringComparison.OrdinalIgnoreCase))
                {
                    configured = mapped;
                }
            }
        }

        return configured ?? first ?? throw new ArgumentException(ApiMessages.BankAccountNotLinked);
    }

    private static LinkedBankAccount? MapAccount(JsonElement account)
    {
        var xid = ReadJsonString(account, "xid");
        if (string.IsNullOrWhiteSpace(xid))
        {
            return null;
        }

        return new LinkedBankAccount(
            xid,
            ReadJsonString(account, "bank_code") ?? "",
            ReadJsonString(account, "bank_bin") ?? "",
            ReadJsonString(account, "account_number") ?? "",
            ReadJsonString(account, "account_holder_name") ?? "");
    }

    private static async Task<string?> ReadTransactionIdAsync(
        HttpResponseMessage response,
        CancellationToken cancellationToken)
    {
        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
        var root = document.RootElement;
        if (root.TryGetProperty("data", out var data) && data.ValueKind == JsonValueKind.Object)
        {
            var nested = ReadJsonString(data, "transaction_id");
            if (!string.IsNullOrWhiteSpace(nested))
            {
                return nested;
            }
        }

        return ReadJsonString(root, "transaction_id");
    }

    private static string? ReadJsonString(JsonElement element, string name)
    {
        if (!element.TryGetProperty(name, out var value))
        {
            return null;
        }

        return value.ValueKind switch
        {
            JsonValueKind.String => value.GetString(),
            JsonValueKind.Number => value.GetRawText(),
            _ => null
        };
    }

    private async Task<string> AccessTokenAsync(SePaySettings settings, CancellationToken cancellationToken)
    {
        await TokenLock.WaitAsync(cancellationToken);
        try
        {
            if (CachedToken is not null && DateTimeOffset.UtcNow < TokenExpiresAt)
            {
                return CachedToken;
            }

            var credentials = Convert.ToBase64String(
                Encoding.UTF8.GetBytes($"{settings.ClientId}:{settings.ClientSecret}"));
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{settings.ApiBaseUrl}/v1/token");
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", credentials);
            using var response = await httpClientFactory.CreateClient(nameof(SePayPaymentService))
                .SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new ArgumentException(ApiMessages.SePayNotConfigured);
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var token = ReadToken(document.RootElement);
            if (string.IsNullOrWhiteSpace(token))
            {
                throw new ArgumentException(ApiMessages.SePayNotConfigured);
            }

            CachedToken = token;
            TokenExpiresAt = DateTimeOffset.UtcNow.AddSeconds(45);
            return token;
        }
        finally
        {
            TokenLock.Release();
        }
    }

    private static string? ReadToken(JsonElement root)
    {
        foreach (var name in new[] { "access_token", "token" })
        {
            if (root.TryGetProperty(name, out var direct) && direct.ValueKind == JsonValueKind.String)
            {
                return direct.GetString();
            }
        }

        if (root.TryGetProperty("data", out var data) && data.ValueKind == JsonValueKind.Object)
        {
            return ReadToken(data);
        }

        return null;
    }

    private static bool IsBankHub(SepayIpnPayload payload) =>
        string.IsNullOrWhiteSpace(payload.NotificationType) &&
        (!string.IsNullOrWhiteSpace(payload.TransferType) ||
            !string.IsNullOrWhiteSpace(payload.Content) ||
            !string.IsNullOrWhiteSpace(payload.PaymentCode));

    private SePaySettings ReadSettings()
    {
        var clientId = configuration["Payments:SePay:ClientId"] ?? configuration["Payments:SePay:MerchantId"];
        var clientSecret = configuration["Payments:SePay:ClientSecret"] ?? configuration["Payments:SePay:SecretKey"];
        var publicBaseUrl = configuration["Payments:SePay:PublicBaseUrl"]?.TrimEnd('/');
        var apiBaseUrl = configuration["Payments:SePay:ApiBaseUrl"]?.TrimEnd('/');
        if (string.IsNullOrWhiteSpace(apiBaseUrl))
        {
            apiBaseUrl = "https://bankhub-api-sandbox.sepay.vn";
        }

        if (string.IsNullOrWhiteSpace(clientId) ||
            string.IsNullOrWhiteSpace(clientSecret) ||
            string.IsNullOrWhiteSpace(configuration["Payments:SePay:IpnSecretKey"]) ||
            !Uri.TryCreate(publicBaseUrl, UriKind.Absolute, out var publicUri) ||
            (publicUri.Scheme != Uri.UriSchemeHttps && publicUri.Scheme != Uri.UriSchemeHttp))
        {
            throw new ArgumentException(ApiMessages.SePayNotConfigured);
        }

        var rateText = configuration["Payments:SePay:EurToVndRate"];
        var rate = decimal.TryParse(rateText, NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed) &&
            parsed > 0
            ? parsed
            : 27000m;
        return new SePaySettings(
            apiBaseUrl,
            clientId,
            clientSecret,
            publicBaseUrl!,
            configuration["Payments:SePay:BankAccountXid"],
            rate);
    }

    private static decimal ToVnd(CustomerOrder order, decimal eurToVndRate)
    {
        decimal vnd;
        if (order.CurrencyCode.Equals("VND", StringComparison.OrdinalIgnoreCase))
        {
            vnd = order.TotalAmount;
        }
        else if (order.CurrencyCode.Equals("EUR", StringComparison.OrdinalIgnoreCase))
        {
            vnd = order.TotalAmount * eurToVndRate;
        }
        else
        {
            throw new ArgumentException(ApiMessages.UnsupportedCheckoutCurrency);
        }

        vnd = decimal.Round(vnd, 0, MidpointRounding.AwayFromZero);
        if (vnd < 1)
        {
            throw new ArgumentException(ApiMessages.UnsupportedCheckoutCurrency);
        }

        return vnd;
    }

    private async Task<Payment?> LatestAsync(
        Guid orderId,
        string provider,
        CancellationToken cancellationToken) =>
        await dbContext.Payments
            .Where(item => item.OrderId == orderId && item.Provider == provider)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

    private async Task CancelOtherPendingAsync(
        Guid orderId,
        Guid keepId,
        CancellationToken cancellationToken)
    {
        var others = await dbContext.Payments
            .Where(item => item.OrderId == orderId && item.Id != keepId && item.Status == "Pending")
            .ToListAsync(cancellationToken);
        var now = DateTimeOffset.UtcNow;
        foreach (var other in others)
        {
            other.Status = "Cancelled";
            other.CompletedAt = now;
        }
    }

    private async Task NotifyAsync(
        CustomerOrder order,
        Payment payment,
        string title,
        string message,
        CancellationToken cancellationToken)
    {
        try
        {
            await notifications.CreateForUserAsync(
                order.UserId,
                new CreateNotificationRequest
                {
                    Type = "payment",
                    Title = title,
                    Message = message,
                    DataJson = JsonSerializer.Serialize(new
                    {
                        orderId = order.Id,
                        paymentId = payment.Id,
                        status = payment.Status
                    })
                },
                cancellationToken);
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, ApiMessages.SePayNotificationFailedLog, order.OrderNumber);
        }
    }

    private static bool SecretsMatch(string? provided, string expected)
    {
        if (string.IsNullOrEmpty(provided))
        {
            return false;
        }

        var providedBytes = Encoding.UTF8.GetBytes(provided);
        var expectedBytes = Encoding.UTF8.GetBytes(expected);
        if (providedBytes.Length != expectedBytes.Length)
        {
            return false;
        }

        return CryptographicOperations.FixedTimeEquals(providedBytes, expectedBytes);
    }

    private static string? ReadReference(SepayIpnTransaction? transaction) =>
        TrimReference(transaction?.TransactionId ?? transaction?.Id);

    private static string? TrimReference(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Length <= 200 ? value : value[..200];
    }

    private static bool AmountMatches(decimal expected, string? received)
    {
        if (!decimal.TryParse(received, NumberStyles.Number, CultureInfo.InvariantCulture, out var actual))
        {
            return false;
        }

        return decimal.Round(actual, 0, MidpointRounding.AwayFromZero) ==
            decimal.Round(expected, 0, MidpointRounding.AwayFromZero);
    }

    private static PaymentSessionResponse Map(
        Payment payment,
        string? checkoutUrl,
        IReadOnlyDictionary<string, string>? fields) =>
        new(
            payment.Id,
            payment.OrderId,
            payment.Provider,
            payment.Method,
            payment.Status,
            payment.Amount,
            payment.CurrencyCode,
            payment.ProviderReference,
            checkoutUrl,
            fields);

    private sealed record LinkedBankAccount(
        string Xid,
        string BankCode,
        string BankBin,
        string AccountNumber,
        string AccountHolderName);

    private sealed record SePaySettings(
        string ApiBaseUrl,
        string ClientId,
        string ClientSecret,
        string PublicBaseUrl,
        string? BankAccountXid,
        decimal EurToVndRate);
}
