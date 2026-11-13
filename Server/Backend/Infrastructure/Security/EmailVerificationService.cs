using BigFit.Application.Abstractions;
using BigFit.Application.Security;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Security;

internal sealed class EmailVerificationService(
    BigFitDbContext dbContext,
    UserManager<ApplicationUser> userManager,
    IEmailSender emailSender,
    IConfiguration configuration,
    ILogger<EmailVerificationService> logger) : IEmailVerificationService
{
    private const string VerifyPurpose = "email-verify";
    private const string ResetPurpose = "password-reset";

    public async Task<RequestEmailVerificationResponse> RequestVerificationAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user?.Email is null)
        {
            return new RequestEmailVerificationResponse(false, null);
        }

        if (user.EmailConfirmed)
        {
            return new RequestEmailVerificationResponse(true, null);
        }

        var token = await IssueTokenAsync(user.Id, VerifyPurpose, TimeSpan.FromHours(24), cancellationToken);
        var link = BuildLink("email/confirm", token);
        var body =
            $"Hello {user.DisplayName},\n\n"
            + $"Confirm your BigFit email: {link}\n\n"
            + "This link expires in 24 hours.";
        await emailSender.SendAsync(user.Email, "Verify your BigFit email", body, cancellationToken);

        var preview = IsLoggingMode() ? link : null;
        return new RequestEmailVerificationResponse(true, preview);
    }

    public async Task<bool> ConfirmEmailAsync(string token, CancellationToken cancellationToken)
    {
        var tokenHash = SecurityTokenHasher.Hash(token);
        var record = await dbContext.EmailVerificationTokens.SingleOrDefaultAsync(
            item =>
                item.TokenHash == tokenHash &&
                item.Purpose == VerifyPurpose &&
                item.ConsumedAt == null &&
                item.ExpiresAt > DateTimeOffset.UtcNow,
            cancellationToken);
        if (record is null)
        {
            return false;
        }

        var user = await userManager.FindByIdAsync(record.UserId.ToString());
        if (user is null)
        {
            return false;
        }

        user.EmailConfirmed = true;
        record.ConsumedAt = DateTimeOffset.UtcNow;
        await userManager.UpdateAsync(user);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> RequestPasswordResetAsync(string email, CancellationToken cancellationToken)
    {
        var user = await userManager.FindByEmailAsync(email.Trim());
        if (user?.Email is null)
        {
            // Do not disclose account existence.
            return true;
        }

        var token = await IssueTokenAsync(user.Id, ResetPurpose, TimeSpan.FromHours(1), cancellationToken);
        var link = BuildLink("password/reset", token);
        var body =
            $"Hello {user.DisplayName},\n\n"
            + $"Reset your BigFit password: {link}\n\n"
            + "If you did not request this, you can ignore this email.";
        await emailSender.SendAsync(user.Email, "Reset your BigFit password", body, cancellationToken);
        if (IsLoggingMode())
        {
            logger.LogWarning("Password reset link for {Email}: {Link}", user.Email, link);
        }

        return true;
    }

    public async Task<bool> CompletePasswordResetAsync(
        string token,
        string newPassword,
        CancellationToken cancellationToken)
    {
        var tokenHash = SecurityTokenHasher.Hash(token);
        var record = await dbContext.EmailVerificationTokens.SingleOrDefaultAsync(
            item =>
                item.TokenHash == tokenHash &&
                item.Purpose == ResetPurpose &&
                item.ConsumedAt == null &&
                item.ExpiresAt > DateTimeOffset.UtcNow,
            cancellationToken);
        if (record is null)
        {
            return false;
        }

        var user = await userManager.FindByIdAsync(record.UserId.ToString());
        if (user is null)
        {
            return false;
        }

        var resetToken = await userManager.GeneratePasswordResetTokenAsync(user);
        var result = await userManager.ResetPasswordAsync(user, resetToken, newPassword);
        if (!result.Succeeded)
        {
            return false;
        }

        record.ConsumedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<string> IssueTokenAsync(
        Guid userId,
        string purpose,
        TimeSpan lifetime,
        CancellationToken cancellationToken)
    {
        var existing = await dbContext.EmailVerificationTokens
            .Where(item => item.UserId == userId && item.Purpose == purpose && item.ConsumedAt == null)
            .ToListAsync(cancellationToken);
        foreach (var item in existing)
        {
            item.ConsumedAt = DateTimeOffset.UtcNow;
        }

        var token = SecurityTokenHasher.GenerateToken();
        dbContext.EmailVerificationTokens.Add(new EmailVerificationToken
        {
            UserId = userId,
            Purpose = purpose,
            TokenHash = SecurityTokenHasher.Hash(token),
            ExpiresAt = DateTimeOffset.UtcNow.Add(lifetime)
        });
        await dbContext.SaveChangesAsync(cancellationToken);
        return token;
    }

    private string BuildLink(string path, string token)
    {
        var baseUrl = configuration["Email:Verification:BaseUrl"]?.TrimEnd('/')
            ?? "https://big-fit-pgm-store.onrender.com/api/security";
        return $"{baseUrl}/{path}?token={Uri.EscapeDataString(token)}";
    }

    private bool IsLoggingMode() => !configuration.GetValue("Email:Enabled", false);
}
