namespace BigFit.Domain.Entities;

/// <summary>One captured line item of an order, snapshotted at order time.</summary>
public sealed class CustomerOrderItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public CustomerOrder Order { get; set; } = null!;
    public Guid? ProductVariantId { get; set; }
    public required string ProductName { get; set; }
    public required string Sku { get; set; }
    public required string Size { get; set; }
    public required string Color { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}
