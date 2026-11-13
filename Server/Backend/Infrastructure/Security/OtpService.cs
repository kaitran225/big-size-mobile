using BigFit.Application;
using BigFit.Application.Abstractions;
using BigFit.Application.Security;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Security;

internal sealed class OtpService(
    BigFitDbContext dbContext,
    IEmailSender emailSender,
    IConfiguration configuration,
    ILogger<OtpService> logger) : IOtpService
{
    public async Task<OtpRequestResponse> RequestAsync(
        Guid? userId,
        RequestOtpRequest request,
        CancellationToken cancellationToken)
    {
        var cooldown = TimeSpan.FromSeconds(
            configuration.GetValue("Email:Otp:ResendCooldownSeconds", 45));
        var expiryMinutes = configuration.GetValue("Email:Otp:ExpiryMinutes", 10);
        var codeLength = configuration.GetValue("Email:Otp:CodeLength", 6);
        var destination = request.Email.Trim();
        var purpose = request.Purpose.Trim();

        var latest = await dbContext.OtpChallenges.AsNoTracking()
            .Where(item =>
                item.Destination == destination &&
                item.Purpose == purpose &&
                item.ConsumedAt == null)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        if (latest?.LastSentAt is not null &&
            DateTimeOffset.UtcNow - latest.LastSentAt < cooldown)
        {
            throw new ArgumentException(ApiMessages.OtpResendTooSoon, nameof(request));
        }

        var code = SecurityTokenHasher.GenerateNumericCode(codeLength);
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(expiryMinutes);
        var challenge = new OtpChallenge
        {
            UserId = userId,
            Destination = destination,
            Purpose = purpose,
            CodeHash = SecurityTokenHasher.Hash(code),
            ExpiresAt = expiresAt,
            LastSentAt = DateTimeOffset.UtcNow
        };
        dbContext.OtpChallenges.Add(challenge);
        await dbContext.SaveChangesAsync(cancellationToken);

        var body =
            $"Your BigFit verification code is {code}. It expires in {expiryMinutes} minutes.";
        await emailSender.SendAsync(destination, "Your BigFit verification code", body, cancellationToken);

        string? preview = null;
        if (!configuration.GetValue("Email:Enabled", false))
        {
            preview = code;
            logger.LogWarning("OTP for {Destination}: {Code}", destination, code);
        }

        return new OtpRequestResponse(true, expiresAt, preview);
    }

    public async Task<OtpVerifyResponse> VerifyAsync(
        VerifyOtpRequest request,
        CancellationToken cancellationToken)
    {
        var maxAttempts = configuration.GetValue("Email:Otp:MaxAttempts", 5);
        var destination = request.Email.Trim();
        var purpose = request.Purpose.Trim();
        var challenge = await dbContext.OtpChallenges
            .Where(item =>
                item.Destination == destination &&
                item.Purpose == purpose &&
                item.ConsumedAt == null)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (challenge is null || challenge.ExpiresAt <= DateTimeOffset.UtcNow)
        {
            return new OtpVerifyResponse(false);
        }

        if (challenge.FailedAttempts >= maxAttempts)
        {
            return new OtpVerifyResponse(false);
        }

        var valid = challenge.CodeHash == SecurityTokenHasher.Hash(request.Code.Trim());
        if (!valid)
        {
            challenge.FailedAttempts += 1;
            await dbContext.SaveChangesAsync(cancellationToken);
            return new OtpVerifyResponse(false);
        }

        challenge.ConsumedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return new OtpVerifyResponse(true);
    }
}
