namespace BigFit.Domain.Entities;

/// <summary>An order placed by a customer.</summary>
public sealed class CustomerOrder
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string OrderNumber { get; set; }
    public Guid UserId { get; set; }
    public Guid? ShippingAddressId { get; set; }
    public string Status { get; set; } = "Pending";
    public decimal Subtotal { get; set; }
    public decimal ShippingAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public required string CurrencyCode { get; set; }
    public string? ShippingAddressSnapshot { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ICollection<CustomerOrderItem> Items { get; set; } = [];
}
