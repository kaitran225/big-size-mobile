namespace BigFit.Domain.Entities;

/// <summary>A queued outbound email awaiting delivery.</summary>
public sealed class EmailOutboxMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; }
    public required string Recipient { get; set; }
    public required string Subject { get; set; }
    public required string TemplateKey { get; set; }
    public string? PayloadJson { get; set; }
    public string Status { get; set; } = "Pending";
    public int AttemptCount { get; set; }
    public DateTimeOffset? NextAttemptAt { get; set; }
    public DateTimeOffset? SentAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
