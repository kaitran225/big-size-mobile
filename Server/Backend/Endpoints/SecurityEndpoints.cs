using System.Security.Claims;
using BigFit.Application;
using BigFit.Application.Abstractions;
using BigFit.Application.Security;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class SecurityEndpoints
{
    public static IEndpointRouteBuilder MapSecurityEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/security")
            .WithTags(ApiMessages.TagSecurity);

        group.MapPost("/email/request-verification", async Task<Ok<RequestEmailVerificationResponse>> (
            IEmailVerificationService emailVerification,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await emailVerification.RequestVerificationAsync(
                    GetUserId(user), cancellationToken)))
            .WithName("RequestEmailVerification")
            .WithSummary(ApiMessages.SummaryRequestEmailVerification)
            .RequireAuthorization();

        group.MapPost("/email/confirm", async Task<Results<Ok, BadRequest>> (
            ConfirmEmailRequest request,
            IEmailVerificationService emailVerification,
            CancellationToken cancellationToken) =>
                await emailVerification.ConfirmEmailAsync(request.Token, cancellationToken)
                    ? TypedResults.Ok()
                    : TypedResults.BadRequest())
            .WithName("ConfirmEmail")
            .WithSummary(ApiMessages.SummaryConfirmEmail)
            .AllowAnonymous();

        group.MapGet("/email/confirm", async Task<Results<Ok, BadRequest>> (
            string token,
            IEmailVerificationService emailVerification,
            CancellationToken cancellationToken) =>
                await emailVerification.ConfirmEmailAsync(token, cancellationToken)
                    ? TypedResults.Ok()
                    : TypedResults.BadRequest())
            .WithName("ConfirmEmailGet")
            .WithSummary(ApiMessages.SummaryConfirmEmail)
            .AllowAnonymous();

        group.MapPost("/password/request-reset", async Task<Ok> (
            PasswordResetRequest request,
            IEmailVerificationService emailVerification,
            CancellationToken cancellationToken) =>
        {
            await emailVerification.RequestPasswordResetAsync(request.Email, cancellationToken);
            return TypedResults.Ok();
        })
        .WithName("RequestPasswordReset")
        .WithSummary(ApiMessages.SummaryRequestPasswordReset)
        .AllowAnonymous()
        .RequireRateLimiting("authentication");

        group.MapPost("/password/reset", async Task<Results<Ok, BadRequest>> (
            CompletePasswordResetRequest request,
            IEmailVerificationService emailVerification,
            CancellationToken cancellationToken) =>
                await emailVerification.CompletePasswordResetAsync(
                    request.Token, request.NewPassword, cancellationToken)
                    ? TypedResults.Ok()
                    : TypedResults.BadRequest())
            .WithName("CompletePasswordReset")
            .WithSummary(ApiMessages.SummaryCompletePasswordReset)
            .AllowAnonymous()
            .RequireRateLimiting("authentication");

        group.MapPost("/otp/request", async Task<Results<Ok<OtpRequestResponse>, BadRequest>> (
            RequestOtpRequest request,
            IOtpService otp,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var userId = user.Identity?.IsAuthenticated == true
                    ? GetUserId(user)
                    : (Guid?)null;
                return TypedResults.Ok(await otp.RequestAsync(userId, request, cancellationToken));
            }
            catch (ArgumentException)
            {
                return TypedResults.BadRequest();
            }
        })
        .WithName("RequestOtp")
        .WithSummary(ApiMessages.SummaryRequestOtp);

        group.MapPost("/otp/verify", async Task<Ok<OtpVerifyResponse>> (
            VerifyOtpRequest request,
            IOtpService otp,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await otp.VerifyAsync(request, cancellationToken)))
            .WithName("VerifyOtp")
            .WithSummary(ApiMessages.SummaryVerifyOtp);

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
