namespace BigFit.Domain.Entities;

/// <summary>One product variant line inside a cart.</summary>
public sealed class ShoppingCartItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CartId { get; set; }
    public ShoppingCart Cart { get; set; } = null!;
    public Guid ProductVariantId { get; set; }
    public ProductVariant ProductVariant { get; set; } = null!;
    public int Quantity { get; set; }
    public DateTimeOffset AddedAt { get; set; } = DateTimeOffset.UtcNow;
}
