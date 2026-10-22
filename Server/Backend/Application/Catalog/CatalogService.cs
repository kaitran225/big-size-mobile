using BigFit.Application.Abstractions;
using BigFit.Domain.Entities;

namespace BigFit.Application.Catalog;

public sealed class CatalogService(ICatalogRepository repository) : ICatalogService
{
    public async Task<IReadOnlyList<CategoryResponse>> GetCategoriesAsync(
        string? gender,
        CancellationToken cancellationToken) =>
        (await repository.GetCategoriesAsync(gender, cancellationToken)).Select(Map).ToArray();

    public async Task<CategoryResponse?> GetCategoryAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await repository.GetCategoryAsync(id, cancellationToken);
        return category is null ? null : Map(category);
    }

    public async Task<CategoryResponse> CreateCategoryAsync(
        CreateCategoryRequest request,
        CancellationToken cancellationToken)
    {
        var category = new Category
        {
            Name = request.Name.Trim(),
            Gender = request.Gender,
            Description = request.Description?.Trim()
        };
        repository.AddCategory(category);
        await repository.SaveChangesAsync(cancellationToken);
        return Map(category);
    }

    public async Task<CategoryResponse?> UpdateCategoryAsync(
        Guid id,
        UpdateCategoryRequest request,
        CancellationToken cancellationToken)
    {
        var category = await repository.GetCategoryAsync(id, cancellationToken);
        if (category is null)
        {
            return null;
        }

        category.Name = request.Name.Trim();
        category.Gender = request.Gender;
        category.Description = request.Description?.Trim();
        await repository.SaveChangesAsync(cancellationToken);
        return Map(category);
    }

    public async Task<int> DeleteCategoryAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await repository.GetCategoryAsync(id, cancellationToken);
        if (category is null)
        {
            return 0;
        }

        if (await repository.CategoryHasProductsAsync(id, cancellationToken))
        {
            return 2;
        }

        repository.RemoveCategory(category);
        await repository.SaveChangesAsync(cancellationToken);
        return 1;
    }

    public async Task<PagedResponse<ProductResponse>> GetProductsAsync(
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
        CancellationToken cancellationToken) =>
        ToPage(await repository.GetProductsAsync(
            search, categoryId, size, color, gender, onSale, inStock, page, pageSize, sortBy, includeInactive, cancellationToken),
            page,
            pageSize);

    public async Task<ProductResponse?> GetProductAsync(
        Guid id,
        bool includeInactive,
        CancellationToken cancellationToken)
    {
        var product = await repository.GetProductAsync(id, includeInactive, cancellationToken);
        return product is null ? null : Map(product);
    }

    public async Task<ProductResponse?> CreateProductAsync(
        CreateProductRequest request,
        CancellationToken cancellationToken)
    {
        if (!await repository.CategoryExistsAsync(request.CategoryId, cancellationToken))
        {
            return null;
        }
        ValidateSalePrice(request.Price, request.SalePrice);

        var product = new Product
        {
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            Price = request.Price,
            SalePrice = request.SalePrice,
            CurrencyCode = request.CurrencyCode,
            ImageUrl = request.ImageUrl,
            IsActive = request.IsActive,
            CategoryId = request.CategoryId,
            Variants = request.Variants.Select(Map).ToList()
        };

        repository.AddProduct(product);
        await repository.SaveChangesAsync(cancellationToken);
        return Map(product);
    }

    public async Task<ProductResponse?> UpdateProductAsync(
        Guid id,
        UpdateProductRequest request,
        CancellationToken cancellationToken)
    {
        var product = await repository.GetProductAsync(id, true, cancellationToken);
        if (product is null || !await repository.CategoryExistsAsync(request.CategoryId, cancellationToken))
        {
            return null;
        }
        ValidateSalePrice(request.Price, request.SalePrice);

        product.Name = request.Name.Trim();
        product.Description = request.Description?.Trim();
        product.Price = request.Price;
        product.SalePrice = request.SalePrice;
        product.CurrencyCode = request.CurrencyCode;
        product.ImageUrl = request.ImageUrl;
        product.IsActive = request.IsActive;
        product.CategoryId = request.CategoryId;
        product.Variants.Clear();
        foreach (var variant in request.Variants)
        {
            product.Variants.Add(Map(variant));
        }

        await repository.SaveChangesAsync(cancellationToken);
        return Map(product);
    }

    public async Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken)
    {
        var product = await repository.GetProductAsync(id, true, cancellationToken);
        if (product is null)
        {
            return false;
        }

        repository.RemoveProduct(product);
        await repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<ProductVariantResponse?> GetProductVariantAsync(
        Guid productId,
        Guid variantId,
        CancellationToken cancellationToken)
    {
        var variant = await repository.GetProductVariantAsync(productId, variantId, cancellationToken);
        return variant is null ? null : Map(variant);
    }

    public async Task<ProductVariantResponse?> CreateProductVariantAsync(
        Guid productId,
        ProductVariantRequest request,
        CancellationToken cancellationToken)
    {
        var product = await repository.GetProductAsync(productId, true, cancellationToken);
        if (product is null)
        {
            return null;
        }

        var variant = Map(request);
        variant.ProductId = product.Id;
        repository.AddProductVariant(variant);
        await repository.SaveChangesAsync(cancellationToken);
        return Map(variant);
    }

    public async Task<ProductVariantResponse?> UpdateProductVariantAsync(
        Guid productId,
        Guid variantId,
        ProductVariantRequest request,
        CancellationToken cancellationToken)
    {
        var variant = await repository.GetProductVariantAsync(productId, variantId, cancellationToken);
        if (variant is null)
        {
            return null;
        }

        variant.Sku = request.Sku.Trim();
        variant.Size = request.Size.Trim();
        variant.Color = request.Color.Trim();
        variant.StockQuantity = request.StockQuantity;
        await repository.SaveChangesAsync(cancellationToken);
        return Map(variant);
    }

    public async Task<bool> DeleteProductVariantAsync(
        Guid productId,
        Guid variantId,
        CancellationToken cancellationToken)
    {
        var variant = await repository.GetProductVariantAsync(productId, variantId, cancellationToken);
        if (variant is null)
        {
            return false;
        }

        repository.RemoveProductVariant(variant);
        await repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static CategoryResponse Map(Category category) =>
        new(category.Id, category.Name, category.Gender, category.Description);

    private static ProductResponse Map(Product product) =>
        new(
            product.Id,
            product.Name,
            product.Description,
            product.Price,
            product.SalePrice,
            product.SalePrice ?? product.Price,
            product.IsOnSale,
            product.CurrencyCode,
            product.ImageUrl,
            product.IsActive,
            product.CategoryId,
            product.CreatedAt,
            product.Variants.Select(variant => new ProductVariantResponse(
                variant.Id,
                variant.Sku,
                variant.Size,
                variant.Color,
                variant.StockQuantity)).ToArray());

    private static PagedResponse<ProductResponse> ToPage(
        (IReadOnlyList<Product> Items, int TotalCount) result,
        int page,
        int pageSize) =>
        new(
            result.Items.Select(Map).ToArray(),
            page,
            pageSize,
            result.TotalCount,
            (int)Math.Ceiling(result.TotalCount / (double)pageSize));

    private static void ValidateSalePrice(decimal price, decimal? salePrice)
    {
        if (salePrice is not null && (salePrice <= 0 || salePrice >= price))
        {
            throw new ArgumentException(ApiMessages.SalePriceOutOfRange);
        }
    }

    private static ProductVariant Map(ProductVariantRequest variant) =>
        new()
        {
            Sku = variant.Sku.Trim(),
            Size = variant.Size.Trim(),
            Color = variant.Color.Trim(),
            StockQuantity = variant.StockQuantity
        };

    private static ProductVariantResponse Map(ProductVariant variant) =>
        new(variant.Id, variant.Sku, variant.Size, variant.Color, variant.StockQuantity);
}
