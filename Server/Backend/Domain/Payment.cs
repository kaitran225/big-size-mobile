namespace BigFit.Domain.Entities;

/// <summary>A payment attempt against an order.</summary>
public sealed class Payment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public required string Provider { get; set; }
    public required string Method { get; set; }
    public string Status { get; set; } = "Pending";
    public decimal Amount { get; set; }
    public required string CurrencyCode { get; set; }
    public string? ProviderReference { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CompletedAt { get; set; }
}
