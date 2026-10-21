namespace BigFit.Application.Catalog;

public interface ICatalogService
{
    Task<IReadOnlyList<CategoryResponse>> GetCategoriesAsync(string? gender, CancellationToken cancellationToken);
    Task<CategoryResponse?> GetCategoryAsync(Guid id, CancellationToken cancellationToken);
    Task<CategoryResponse> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken cancellationToken);
    Task<CategoryResponse?> UpdateCategoryAsync(Guid id, UpdateCategoryRequest request, CancellationToken cancellationToken);
    Task<int> DeleteCategoryAsync(Guid id, CancellationToken cancellationToken);

    Task<PagedResponse<ProductResponse>> GetProductsAsync(
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
    Task<ProductResponse?> GetProductAsync(Guid id, bool includeInactive, CancellationToken cancellationToken);
    Task<ProductResponse?> CreateProductAsync(CreateProductRequest request, CancellationToken cancellationToken);
    Task<ProductResponse?> UpdateProductAsync(Guid id, UpdateProductRequest request, CancellationToken cancellationToken);
    Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken);

    Task<ProductVariantResponse?> GetProductVariantAsync(
        Guid productId,
        Guid variantId,
        CancellationToken cancellationToken);
    Task<ProductVariantResponse?> CreateProductVariantAsync(
        Guid productId,
        ProductVariantRequest request,
        CancellationToken cancellationToken);
    Task<ProductVariantResponse?> UpdateProductVariantAsync(
        Guid productId,
        Guid variantId,
        ProductVariantRequest request,
        CancellationToken cancellationToken);
    Task<bool> DeleteProductVariantAsync(Guid productId, Guid variantId, CancellationToken cancellationToken);
}
