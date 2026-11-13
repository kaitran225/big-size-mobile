using System.Globalization;
using System.Net;
using System.Net.Http.Headers;
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
    private const int DefaultTokenTtlSeconds = 600;
    private const int MinimumTokenTtlSeconds = 60;
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
        var account = await ResolveTransferAccountAsync(settings, cancellationToken);
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
            var settledAccount = await ResolveTransferAccountAsync(ReadSettings(), cancellationToken);
            return Map(payment, null, TransferFields(order, payment, settledAccount));
        }
        if (payment.Status != "Pending")
        {
            throw new DataConflictException(ApiMessages.PaymentAttemptNotPending);
        }

        var settings = ReadSettings();
        string? transactionId = null;
        if (settings.IsConfigured)
        {
            try
            {
                var account = await LoadLinkedAccountAsync(settings, cancellationToken);
                using var response = await SendAuthorizedAsync(
                    settings,
                    token =>
                    {
                        var request = new HttpRequestMessage(
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
                        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                        return request;
                    },
                    cancellationToken);
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                if (response.IsSuccessStatusCode)
                {
                    transactionId = ReadTransactionId(body);
                    if (string.IsNullOrWhiteSpace(transactionId))
                    {
                        logger.LogWarning(
                            "Bank Hub sandbox transaction create returned no transaction id: {Body}",
                            Truncate(body, 400));
                    }
                }
                else
                {
                    logger.LogWarning(
                        "Bank Hub sandbox transaction create failed with status {StatusCode}: {Body}",
                        (int)response.StatusCode,
                        Truncate(body, 400));
                }
            }
            catch (PaymentProviderUnavailableException exception)
            {
                logger.LogWarning(
                    "Bank Hub sandbox credit unavailable ({Reason}). Confirming the payment locally.",
                    exception.Message);
            }
        }
        else
        {
            logger.LogInformation(ApiMessages.SandboxNotConfiguredLog, order.OrderNumber);
        }

        // SePay posts the credit to the IPN within a second or two. Give it a moment first so the
        // demo really goes through the callback and not just this request.
        var confirmedByIpn = transactionId is not null &&
            await WaitForIpnAsync(payment.Id, TimeSpan.FromSeconds(3), cancellationToken);
        dbContext.ChangeTracker.Clear();

        var trackedOrder = await dbContext.Orders.SingleAsync(
            item => item.Id == order.Id, cancellationToken);
        var trackedPayment = await dbContext.Payments.SingleAsync(
            item => item.Id == payment.Id, cancellationToken);
        if (trackedPayment.Status is "Failed" or "Cancelled")
        {
            throw new DataConflictException(ApiMessages.PaymentAttemptNotPending);
        }

        if (trackedPayment.Status == "Pending")
        {
            if (!confirmedByIpn)
            {
                logger.LogInformation(
                    ApiMessages.SandboxIpnMissingLog,
                    order.OrderNumber,
                    transactionId ?? ApiMessages.SandboxLocalReference);
            }

            await MarkTransferSucceededAsync(
                trackedOrder,
                trackedPayment,
                transactionId ?? $"DEMO-{payment.Id:N}",
                cancellationToken);
        }
        else
        {
            logger.LogInformation(
                ApiMessages.SandboxIpnConfirmedLog,
                order.OrderNumber,
                transactionId);
        }

        var transferAccount = await ResolveTransferAccountAsync(settings, cancellationToken);
        return Map(trackedPayment, null, TransferFields(trackedOrder, trackedPayment, transferAccount));
    }

    public async Task<SepaySandboxStatusResponse> GetSandboxStatusAsync(CancellationToken cancellationToken)
    {
        var clientId = ClientId();
        var clientSecret = ClientSecret();
        var ipnKey = configuration["Payments:SePay:IpnSecretKey"];
        var publicBaseUrl = configuration["Payments:SePay:PublicBaseUrl"]?.TrimEnd('/');
        var status = new SepaySandboxStatusResponse(
            "localDemo",
            !string.IsNullOrWhiteSpace(clientId),
            !string.IsNullOrWhiteSpace(clientSecret),
            !string.IsNullOrWhiteSpace(ipnKey),
            !string.IsNullOrWhiteSpace(configuration["Payments:SePay:BankAccountXid"]),
            ApiBaseUrl(),
            string.IsNullOrWhiteSpace(publicBaseUrl)
                ? null
                : $"{publicBaseUrl}/api/payments/sepay/ipn",
            null,
            null,
            null,
            null,
            null);

        var demo = DemoAccount();
        status = status with
        {
            LinkedBankAccountXid = demo.Xid,
            BankCode = demo.BankCode,
            AccountNumber = demo.AccountNumber,
            AccountHolderName = demo.AccountHolderName
        };

        var settings = ReadSettings();
        if (!settings.IsConfigured)
        {
            return status with { Error = ApiMessages.SePayNotConfigured };
        }

        try
        {
            var account = await LoadLinkedAccountAsync(settings, cancellationToken);
            return status with
            {
                Mode = "bankHub",
                LinkedBankAccountXid = account.Xid,
                BankCode = account.BankCode,
                AccountNumber = account.AccountNumber,
                AccountHolderName = account.AccountHolderName
            };
        }
        catch (PaymentProviderUnavailableException exception)
        {
            return status with { Error = exception.Message };
        }
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

        var exact = await dbContext.Orders.SingleOrDefaultAsync(
            item => item.OrderNumber == content &&
                (item.Status == "Pending" || item.Status == "Confirmed"),
            cancellationToken);
        if (exact is not null)
        {
            return exact;
        }

        // Real transfers carry the order number inside bank text, so fall back to a containment match.
        // Only accept an unambiguous hit to avoid confirming the wrong order.
        var matches = await dbContext.Orders
            .Where(item => (item.Status == "Pending" || item.Status == "Confirmed") &&
                content.Contains(item.OrderNumber))
            .OrderByDescending(item => item.CreatedAt)
            .Take(2)
            .ToListAsync(cancellationToken);
        return matches.Count == 1 ? matches[0] : null;
    }

    private async Task<LinkedBankAccount> LoadLinkedAccountAsync(
        SePaySettings settings,
        CancellationToken cancellationToken)
    {
        using var response = await SendAuthorizedAsync(
            settings,
            token =>
            {
                var request = new HttpRequestMessage(
                    HttpMethod.Get,
                    $"{settings.ApiBaseUrl}/v1/bank-account?page=1&per_page=20");
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                return request;
            },
            cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "Bank Hub linked account request failed with status {StatusCode}.",
                (int)response.StatusCode);
            throw new PaymentProviderUnavailableException(ApiMessages.PaymentProviderUnavailable);
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
                if (mapped is null ||
                    string.Equals(ReadJsonString(account, "active"), "0", StringComparison.OrdinalIgnoreCase))
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

        return configured ?? first ??
            throw new PaymentProviderUnavailableException(ApiMessages.BankAccountNotLinked);
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

    private static string? ReadTransactionId(string body)
    {
        if (string.IsNullOrWhiteSpace(body))
        {
            return null;
        }

        using var document = JsonDocument.Parse(body);
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

    /// <summary>Waits for the IPN to flip a pending payment so the demo exercises the callback.</summary>
    private async Task<bool> WaitForIpnAsync(
        Guid paymentId,
        TimeSpan timeout,
        CancellationToken cancellationToken)
    {
        var deadline = DateTimeOffset.UtcNow.Add(timeout);
        while (DateTimeOffset.UtcNow < deadline)
        {
            dbContext.ChangeTracker.Clear();
            var status = await dbContext.Payments.AsNoTracking()
                .Where(item => item.Id == paymentId)
                .Select(item => item.Status)
                .SingleOrDefaultAsync(cancellationToken);
            if (status == "Succeeded")
            {
                return true;
            }

            await Task.Delay(250, cancellationToken);
        }

        return false;
    }

    private static string Truncate(string value, int length) =>
        value.Length <= length ? value : value[..length];

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

    private async Task<string> AccessTokenAsync(
        SePaySettings settings,
        bool forceRefresh,
        CancellationToken cancellationToken)
    {
        await TokenLock.WaitAsync(cancellationToken);
        try
        {
            if (!forceRefresh && CachedToken is not null && DateTimeOffset.UtcNow < TokenExpiresAt)
            {
                return CachedToken;
            }

            var credentials = Convert.ToBase64String(
                Encoding.UTF8.GetBytes($"{settings.ClientId}:{settings.ClientSecret}"));
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{settings.ApiBaseUrl}/v1/token");
            request.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);
            using var response = await SendProviderRequestAsync(request, cancellationToken);
            if (response.StatusCode == HttpStatusCode.Unauthorized)
            {
                logger.LogWarning("Bank Hub rejected the configured client id and client secret.");
                throw new PaymentProviderUnavailableException(ApiMessages.SePayInvalidCredentials);
            }

            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning(
                    "Bank Hub token request failed with status {StatusCode}.",
                    (int)response.StatusCode);
                throw new PaymentProviderUnavailableException(ApiMessages.PaymentProviderUnavailable);
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var token = ReadToken(document.RootElement);
            if (string.IsNullOrWhiteSpace(token))
            {
                throw new PaymentProviderUnavailableException(ApiMessages.PaymentProviderUnavailable);
            }

            var ttl = ReadTokenTtl(document.RootElement) ?? DefaultTokenTtlSeconds;
            CachedToken = token;
            TokenExpiresAt = DateTimeOffset.UtcNow.AddSeconds(
                Math.Max(MinimumTokenTtlSeconds, ttl - 60));
            return token;
        }
        finally
        {
            TokenLock.Release();
        }
    }

    /// <summary>Sends a Bank Hub request and refreshes the access token once when it expired.</summary>
    private async Task<HttpResponseMessage> SendAuthorizedAsync(
        SePaySettings settings,
        Func<string, HttpRequestMessage> buildRequest,
        CancellationToken cancellationToken)
    {
        var token = await AccessTokenAsync(settings, false, cancellationToken);
        var response = await SendProviderRequestAsync(buildRequest(token), cancellationToken);
        if (response.StatusCode != HttpStatusCode.Unauthorized)
        {
            return response;
        }

        response.Dispose();
        token = await AccessTokenAsync(settings, true, cancellationToken);
        return await SendProviderRequestAsync(buildRequest(token), cancellationToken);
    }

    private static int? ReadTokenTtl(JsonElement root)
    {
        if (root.TryGetProperty("ttl", out var ttl) && ttl.ValueKind == JsonValueKind.Number &&
            ttl.TryGetInt32(out var seconds))
        {
            return seconds;
        }

        return null;
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

    private async Task<HttpResponseMessage> SendProviderRequestAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        try
        {
            return await httpClientFactory.CreateClient(nameof(SePayPaymentService))
                .SendAsync(request, cancellationToken);
        }
        catch (HttpRequestException exception)
        {
            throw new PaymentProviderUnavailableException(
                ApiMessages.PaymentProviderUnavailable,
                exception);
        }
        catch (TaskCanceledException exception) when (!cancellationToken.IsCancellationRequested)
        {
            throw new PaymentProviderUnavailableException(
                ApiMessages.PaymentProviderUnavailable,
                exception);
        }
    }

    private static bool IsBankHub(SepayIpnPayload payload) =>
        string.IsNullOrWhiteSpace(payload.NotificationType) &&
        (!string.IsNullOrWhiteSpace(payload.TransferType) ||
            !string.IsNullOrWhiteSpace(payload.Content) ||
            !string.IsNullOrWhiteSpace(payload.PaymentCode));

    private SePaySettings ReadSettings()
    {
        var apiBaseUrl = ApiBaseUrl();
        if (!Uri.TryCreate(apiBaseUrl, UriKind.Absolute, out _))
        {
            throw new PaymentProviderUnavailableException(ApiMessages.SePayNotConfigured);
        }

        var rateText = configuration["Payments:SePay:EurToVndRate"];
        var rate = decimal.TryParse(rateText, NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed) &&
            parsed > 0
            ? parsed
            : 27000m;
        return new SePaySettings(
            apiBaseUrl,
            ClientId() ?? string.Empty,
            ClientSecret() ?? string.Empty,
            configuration["Payments:SePay:PublicBaseUrl"]?.TrimEnd('/') ?? string.Empty,
            configuration["Payments:SePay:BankAccountXid"],
            rate,
            !string.IsNullOrWhiteSpace(ClientId()) &&
                !string.IsNullOrWhiteSpace(ClientSecret()) &&
                !string.IsNullOrWhiteSpace(configuration["Payments:SePay:IpnSecretKey"]));
    }

    /// <summary>The real linked account when Bank Hub answers, otherwise the configured demo account.</summary>
    private async Task<LinkedBankAccount> ResolveTransferAccountAsync(
        SePaySettings settings,
        CancellationToken cancellationToken)
    {
        if (!settings.IsConfigured)
        {
            return DemoAccount();
        }

        try
        {
            return await LoadLinkedAccountAsync(settings, cancellationToken);
        }
        catch (PaymentProviderUnavailableException exception)
        {
            logger.LogWarning(
                "Bank Hub linked account unavailable ({Reason}). Showing the demo account instead.",
                exception.Message);
            return DemoAccount();
        }
    }

    /// <summary>Placeholder transfer details so checkout works before Bank Hub is configured.</summary>
    private LinkedBankAccount DemoAccount() => new(
        configuration["Payments:SePay:DemoAccountXid"] ?? "local-demo-account",
        configuration["Payments:SePay:DemoBankCode"] ?? "MBBank",
        configuration["Payments:SePay:DemoBankBin"] ?? "970422",
        configuration["Payments:SePay:DemoAccountNumber"] ?? "0123456789",
        configuration["Payments:SePay:DemoAccountHolderName"] ?? "NGUYEN VAN A");

    private string? ClientId() =>
        configuration["Payments:SePay:ClientId"] ?? configuration["Payments:SePay:MerchantId"];

    private string? ClientSecret() =>
        configuration["Payments:SePay:ClientSecret"] ?? configuration["Payments:SePay:SecretKey"];

    private string ApiBaseUrl() =>
        configuration["Payments:SePay:ApiBaseUrl"]?.TrimEnd('/') is { Length: > 0 } configured
            ? configured
            : "https://bankhub-api-sandbox.sepay.vn";

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
        decimal EurToVndRate,
        bool IsConfigured);
}
