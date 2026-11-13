using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Security;

public sealed record RequestEmailVerificationResponse(bool Sent, string? DevPreview);

public sealed record ConfirmEmailRequest
{
    [Required, MinLength(32), MaxLength(512)]
    public required string Token { get; init; }
}

public sealed record PasswordResetRequest
{
    [Required, EmailAddress]
    public required string Email { get; init; }
}

public sealed record CompletePasswordResetRequest
{
    [Required, MinLength(32), MaxLength(512)]
    public required string Token { get; init; }

    [Required, MinLength(12), MaxLength(128)]
    public required string NewPassword { get; init; }
}

public sealed record RequestOtpRequest
{
    [Required, EmailAddress]
    public required string Email { get; init; }

    [Required, MaxLength(40)]
    public required string Purpose { get; init; }
}

public sealed record VerifyOtpRequest
{
    [Required, EmailAddress]
    public required string Email { get; init; }

    [Required, MaxLength(40)]
    public required string Purpose { get; init; }

    [Required, MinLength(4), MaxLength(12)]
    public required string Code { get; init; }
}

public sealed record OtpRequestResponse(bool Sent, DateTimeOffset ExpiresAt, string? DevPreview);

public sealed record OtpVerifyResponse(bool Verified);
