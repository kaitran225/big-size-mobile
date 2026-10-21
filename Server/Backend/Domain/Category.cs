namespace BigFit.Domain.Entities;

public sealed class Category
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public string Gender { get; set; } = "Unisex";
    public string? Description { get; set; }
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
