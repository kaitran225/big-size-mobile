namespace BigFit.Domain.Entities;

/// <summary>A notification shown to a customer in the app.</summary>
public sealed class UserNotification
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public required string Type { get; set; }
    public required string Title { get; set; }
    public required string Message { get; set; }
    public string? DataJson { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ReadAt { get; set; }
}
