using System.Security.Claims;
using BigFit.Application.Abstractions;
using BigFit.Application.Payments;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class PaymentEndpoints
{
    public static IEndpointRouteBuilder MapPaymentEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var orders = endpoints.MapGroup("/api/orders")
            .WithTags(ApiMessages.TagPayments)
            .RequireAuthorization();

        orders.MapPost("/{orderId:guid}/payments", async Task<Ok<PaymentSessionResponse>> (
            Guid orderId,
            CreatePaymentRequest request,
            IPaymentService payments,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await payments.CreateAsync(
                    GetUserId(user),
                    orderId,
                    request.Method,
                    cancellationToken)))
            .WithName("CreateOrderPayment")
            .WithSummary(ApiMessages.SummaryCreatePayment);

        orders.MapGet("/{orderId:guid}/payments/latest", async Task<Results<Ok<PaymentSessionResponse>, NotFound>> (
            Guid orderId,
            IPaymentService payments,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var payment = await payments.GetLatestAsync(GetUserId(user), orderId, cancellationToken);
            return payment is null ? TypedResults.NotFound() : TypedResults.Ok(payment);
        })
            .WithName("GetLatestOrderPayment")
            .WithSummary(ApiMessages.SummaryGetLatestPayment);

        orders.MapPost("/{orderId:guid}/payments/{paymentId:guid}/result", async Task<Ok<PaymentSessionResponse>> (
            Guid orderId,
            Guid paymentId,
            PaymentClientResultRequest request,
            IPaymentService payments,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await payments.ReportClientResultAsync(
                    GetUserId(user),
                    orderId,
                    paymentId,
                    request.Result,
                    cancellationToken)))
            .WithName("ReportOrderPaymentResult")
            .WithSummary(ApiMessages.SummaryReportPaymentResult);

        orders.MapPost("/{orderId:guid}/payments/{paymentId:guid}/simulate", async Task<Ok<PaymentSessionResponse>> (
            Guid orderId,
            Guid paymentId,
            IPaymentService payments,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await payments.SimulateSandboxPaymentAsync(
                    GetUserId(user),
                    orderId,
                    paymentId,
                    cancellationToken)))
            .WithName("SimulateSandboxPayment")
            .WithSummary(ApiMessages.SummarySimulatePayment);

        endpoints.MapGet("/api/payments/sepay/account", async Task<Ok<SepayBankAccountResponse>> (
            IPaymentService payments,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await payments.GetLinkedBankAccountAsync(cancellationToken)))
            .RequireAuthorization()
            .WithTags(ApiMessages.TagPayments)
            .WithName("GetSePayBankAccount")
            .WithSummary(ApiMessages.SummaryGetSePayBankAccount);

        endpoints.MapGet("/api/payments/sepay/status", async Task<Ok<SepaySandboxStatusResponse>> (
            IPaymentService payments,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await payments.GetSandboxStatusAsync(cancellationToken)))
            .RequireAuthorization()
            .WithTags(ApiMessages.TagPayments)
            .WithName("GetSePaySandboxStatus")
            .WithSummary(ApiMessages.SummaryGetSePaySandboxStatus);

        var sepay = endpoints.MapGroup("/api/payments/sepay")
            .WithTags(ApiMessages.TagPayments)
            .AllowAnonymous();

        sepay.MapPost("/ipn", async Task<IResult> (
            HttpRequest request,
            SepayIpnPayload payload,
            IPaymentService payments,
            CancellationToken cancellationToken) =>
        {
            var secret = request.Headers["X-Secret-Key"].ToString();
            if (string.IsNullOrWhiteSpace(secret))
            {
                var authorization = request.Headers.Authorization.ToString();
                const string apiKeyPrefix = "Apikey ";
                if (authorization.StartsWith(apiKeyPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    secret = authorization[apiKeyPrefix.Length..].Trim();
                }
            }

            var accepted = await payments.HandleIpnAsync(secret, payload, cancellationToken);
            return accepted
                ? Results.Json(new SepayAck(true))
                : Results.Json(new SepayAck(false), statusCode: StatusCodes.Status401Unauthorized);
        })
            .WithName("ReceiveSePayIpn")
            .WithSummary(ApiMessages.SummarySePayIpn);

        sepay.MapGet("/return", (string? result) =>
        {
            var message = result switch
            {
                "success" => ApiMessages.PaymentReturnSuccess,
                "error" => ApiMessages.PaymentReturnError,
                "cancel" => ApiMessages.PaymentReturnCancel,
                _ => ApiMessages.PaymentReturnUnknown
            };
            var html = $$"""
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1">
                  <title>BigFit</title>
                </head>
                <body style="font-family: sans-serif; padding: 24px;">
                  <h1>BigFit</h1>
                  <p>{{System.Net.WebUtility.HtmlEncode(message)}}</p>
                </body>
                </html>
                """;
            return Results.Content(html, "text/html; charset=utf-8");
        })
            .WithName("SePayCheckoutReturn")
            .WithSummary(ApiMessages.SummarySePayReturn);

        return endpoints;
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var subject = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.TryParse(subject, out var userId)
            ? userId
            : throw new InvalidOperationException(ApiMessages.AuthenticatedTokenWithoutUserId);
    }
}

/// <summary>Input to start a payment for an existing order.</summary>
public sealed class CreatePaymentRequest
{
    public string Method { get; init; } = "";
}

/// <summary>Customer-side checkout outcome. Success is confirmed only by IPN.</summary>
public sealed class PaymentClientResultRequest
{
    public string Result { get; init; } = "";
}
