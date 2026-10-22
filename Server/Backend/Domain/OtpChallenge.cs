namespace BigFit.Domain.Entities;

/// <summary>A one-time passcode challenge sent to a customer.</summary>
public sealed class OtpChallenge
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; }
    public required string Destination { get; set; }
    public required string Purpose { get; set; }
    public required string CodeHash { get; set; }
    public int FailedAttempts { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset? ConsumedAt { get; set; }
    public DateTimeOffset? LastSentAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
