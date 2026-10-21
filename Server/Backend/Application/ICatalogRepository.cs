using BigFit.Domain.Entities;

namespace BigFit.Application.Abstractions;

public interface ICatalogRepository
{
    Task<IReadOnlyList<Category>> GetCategoriesAsync(string? gender, CancellationToken cancellationToken);
    Task<Category?> GetCategoryAsync(Guid id, CancellationToken cancellationToken);
    Task<bool> CategoryHasProductsAsync(Guid id, CancellationToken cancellationToken);
    void AddCategory(Category category);
    void RemoveCategory(Category category);

    Task<(IReadOnlyList<Product> Items, int TotalCount)> GetProductsAsync(
        string? search,
        Guid? categoryId,
        string? size,
        string? color,
        string? gender,
        bool onSale,
        bool inStock,
        int page,
        int pageSize,
        string? sortBy,
        bool includeInactive,
        CancellationToken cancellationToken);
    Task<Product?> GetProductAsync(Guid id, bool includeInactive, CancellationToken cancellationToken);
    Task<ProductVariant?> GetProductVariantAsync(
        Guid productId,
        Guid variantId,
        CancellationToken cancellationToken);
    Task<bool> CategoryExistsAsync(Guid id, CancellationToken cancellationToken);
    void AddProduct(Product product);
    void RemoveProduct(Product product);
    void AddProductVariant(ProductVariant variant);
    void RemoveProductVariant(ProductVariant variant);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}
