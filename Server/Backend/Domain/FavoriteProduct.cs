namespace BigFit.Domain.Entities;

/// <summary>A product a customer has favorited.</summary>
public sealed class FavoriteProduct
{
    public Guid UserId { get; set; }
    public Guid ProductId { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
