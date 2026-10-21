using BigFit.Application.Abstractions;
using BigFit.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace BigFit.Infrastructure.Persistence;

internal sealed class CatalogRepository(BigFitDbContext dbContext) : ICatalogRepository
{
    public async Task<IReadOnlyList<Category>> GetCategoriesAsync(string? gender, CancellationToken cancellationToken)
    {
        var query = dbContext.Categories.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(gender))
        {
            query = query.Where(category => category.Gender == gender);
        }

        return await query.OrderBy(category => category.Gender)
            .ThenBy(category => category.Name)
            .ToListAsync(cancellationToken);
    }

    public Task<Category?> GetCategoryAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Categories.SingleOrDefaultAsync(category => category.Id == id, cancellationToken);

    public Task<bool> CategoryHasProductsAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Products.AnyAsync(product => product.CategoryId == id, cancellationToken);

    public void AddCategory(Category category) => dbContext.Categories.Add(category);

    public void RemoveCategory(Category category) => dbContext.Categories.Remove(category);

    public async Task<(IReadOnlyList<Product> Items, int TotalCount)> GetProductsAsync(
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
        CancellationToken cancellationToken)
    {
        var query = dbContext.Products.AsNoTracking().Include(product => product.Variants).AsQueryable();
        if (!includeInactive)
        {
            query = query.Where(product => product.IsActive);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var pattern = $"%{EscapeLikePattern(search.Trim())}%";
            query = query.Where(product =>
                EF.Functions.ILike(product.Name, pattern) ||
                (product.Description != null && EF.Functions.ILike(product.Description, pattern)));
        }

        if (categoryId.HasValue)
        {
            query = query.Where(product => product.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(gender))
        {
            query = query.Where(product => product.Category.Gender == gender);
        }

        if (onSale)
        {
            query = query.Where(product => product.SalePrice != null);
        }

        if (inStock)
        {
            query = query.Where(product => product.Variants.Any(variant => variant.StockQuantity > 0));
        }

        if (!string.IsNullOrWhiteSpace(size))
        {
            query = query.Where(product => product.Variants.Any(variant => variant.Size == size.Trim()));
        }

        if (!string.IsNullOrWhiteSpace(color))
        {
            query = query.Where(product => product.Variants.Any(variant => variant.Color == color.Trim()));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        query = sortBy?.ToLowerInvariant() switch
        {
            "price_asc" => query.OrderBy(product => product.SalePrice ?? product.Price).ThenBy(product => product.Name),
            "price_desc" => query.OrderByDescending(product => product.SalePrice ?? product.Price).ThenBy(product => product.Name),
            "newest" => query.OrderByDescending(product => product.CreatedAt),
            _ => query.OrderBy(product => product.Name)
        };

        var items = await query.Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return (items, totalCount);
    }

    public Task<Product?> GetProductAsync(Guid id, bool includeInactive, CancellationToken cancellationToken)
    {
        var query = dbContext.Products.AsQueryable();
        if (!includeInactive)
        {
            query = query.Where(product => product.IsActive);
        }

        return query
            .Include(product => product.Variants)
            .SingleOrDefaultAsync(product => product.Id == id, cancellationToken);
    }

    public Task<ProductVariant?> GetProductVariantAsync(
        Guid productId,
        Guid variantId,
        CancellationToken cancellationToken) =>
        dbContext.ProductVariants.SingleOrDefaultAsync(
            variant => variant.ProductId == productId && variant.Id == variantId,
            cancellationToken);

    public Task<bool> CategoryExistsAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Categories.AnyAsync(category => category.Id == id, cancellationToken);

    public void AddProduct(Product product) => dbContext.Products.Add(product);

    public void RemoveProduct(Product product) => dbContext.Products.Remove(product);

    public void AddProductVariant(ProductVariant variant) => dbContext.ProductVariants.Add(variant);

    public void RemoveProductVariant(ProductVariant variant) => dbContext.ProductVariants.Remove(variant);

    public async Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException exception) when (exception.InnerException is PostgresException
        {
            SqlState: PostgresErrorCodes.UniqueViolation
        })
        {
            throw new DataConflictException(
                "The category name or variant SKU/size/color combination already exists.",
                exception);
        }
    }

    private static string EscapeLikePattern(string value) =>
        value.Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("%", "\\%", StringComparison.Ordinal)
            .Replace("_", "\\_", StringComparison.Ordinal);
}
