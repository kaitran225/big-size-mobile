namespace BigFit.Domain.Entities;

/// <summary>A size and colour of a product, with its own stock.</summary>
public sealed class ProductVariant
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;
    public required string Sku { get; set; }
    public required string Size { get; set; }
    public required string Color { get; set; }
    public int StockQuantity { get; set; }
}
