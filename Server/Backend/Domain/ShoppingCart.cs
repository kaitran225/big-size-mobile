namespace BigFit.Domain.Entities;

/// <summary>The cart of one customer.</summary>
public sealed class ShoppingCart
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ICollection<ShoppingCartItem> Items { get; set; } = [];
}
