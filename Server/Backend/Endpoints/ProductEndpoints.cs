using BigFit.Application.Catalog;
using BigFit.Application.Authentication;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BigFit.Api.Endpoints;

public static class ProductEndpoints
{
    public static IEndpointRouteBuilder MapProductEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/products").WithTags("Products");

        group.MapGet("/", async Task<Results<Ok<PagedResponse<ProductResponse>>, BadRequest<ProblemDetails>, ForbidHttpResult>> (
            ICatalogService catalog,
            string? search,
            Guid? categoryId,
            string? size,
            string? color,
            string? gender,
            bool? onSale,
            bool? inStock,
            int? page,
            int? pageSize,
            string? sortBy,
            bool? includeInactive,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var showInactive = includeInactive ?? false;
            if (showInactive && !user.IsInRole(ApplicationRoles.Admin) && !user.IsInRole(ApplicationRoles.StoreStaff))
            {
                return TypedResults.Forbid();
            }

            var requestedPage = page ?? 1;
            var requestedPageSize = pageSize ?? 24;
            if (requestedPage < 1 || requestedPageSize is < 1 or > 100)
            {
                return TypedResults.BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Invalid pagination",
                    Detail = "Page must be at least 1 and pageSize must be between 1 and 100."
                });
            }

            var supportedSort = new[] { "name", "price_asc", "price_desc", "newest" };
            if (sortBy is not null && !supportedSort.Contains(sortBy, StringComparer.OrdinalIgnoreCase))
            {
                return TypedResults.BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Unsupported sort order",
                    Detail = "sortBy must be name, price_asc, price_desc, or newest."
                });
            }

            if (gender is not null && gender is not ("Men" or "Women" or "Unisex"))
            {
                return TypedResults.BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Unsupported gender",
                    Detail = "gender must be Men, Women, or Unisex."
                });
            }

            return TypedResults.Ok(await catalog.GetProductsAsync(
                search,
                categoryId,
                size,
                color,
                gender,
                onSale ?? false,
                inStock ?? false,
                requestedPage,
                requestedPageSize,
                sortBy,
                showInactive,
                cancellationToken));
        })
            .WithName("GetProducts")
            .WithSummary("List and filter catalogue products")
            .WithDescription("Supports text search, gender, category, size, color, sale, stock, sorting, and pagination.");

        group.MapGet("/{id:guid}", async Task<Results<Ok<ProductResponse>, NotFound, ForbidHttpResult>> (
            Guid id,
            bool? includeInactive,
            ClaimsPrincipal user,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var showInactive = includeInactive ?? false;
            if (showInactive && !user.IsInRole(ApplicationRoles.Admin) && !user.IsInRole(ApplicationRoles.StoreStaff))
            {
                return TypedResults.Forbid();
            }

            var product = await catalog.GetProductAsync(id, showInactive, cancellationToken);
            return product is null ? TypedResults.NotFound() : TypedResults.Ok(product);
        })
        .WithName("GetProduct")
        .WithSummary("Get a product and its variants by ID");

        group.MapPost("/", async Task<Results<Created<ProductResponse>, NotFound>> (
            CreateProductRequest request,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var product = await catalog.CreateProductAsync(request, cancellationToken);
            return product is null
                ? TypedResults.NotFound()
                : TypedResults.Created($"/api/products/{product.Id}", product);
        })
        .WithName("CreateProduct")
        .WithSummary("Create a product with size/color variants and optional sale price")
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        group.MapPut("/{id:guid}", async Task<Results<Ok<ProductResponse>, NotFound>> (
            Guid id,
            UpdateProductRequest request,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var product = await catalog.UpdateProductAsync(id, request, cancellationToken);
            return product is null ? TypedResults.NotFound() : TypedResults.Ok(product);
        })
        .WithName("UpdateProduct")
        .WithSummary("Replace a product and its variants")
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        group.MapDelete("/{id:guid}", async Task<Results<NoContent, NotFound>> (
            Guid id,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
                await catalog.DeleteProductAsync(id, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("DeleteProduct")
            .WithSummary("Delete a product")
            .RequireAuthorization(ApplicationRoles.CatalogManagement);

        var variantGroup = endpoints
            .MapGroup("/api/products/{productId:guid}/variants")
            .WithTags("Product variants");

        variantGroup.MapGet("/{variantId:guid}", async Task<Results<Ok<ProductVariantResponse>, NotFound>> (
            Guid productId,
            Guid variantId,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var variant = await catalog.GetProductVariantAsync(productId, variantId, cancellationToken);
            return variant is null ? TypedResults.NotFound() : TypedResults.Ok(variant);
        })
        .WithName("GetProductVariant")
        .WithSummary("Get a product variant");

        variantGroup.MapPost("/", async Task<Results<Created<ProductVariantResponse>, NotFound>> (
            Guid productId,
            ProductVariantRequest request,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var variant = await catalog.CreateProductVariantAsync(productId, request, cancellationToken);
            return variant is null
                ? TypedResults.NotFound()
                : TypedResults.Created($"/api/products/{productId}/variants/{variant.Id}", variant);
        })
        .WithName("CreateProductVariant")
        .WithSummary("Add a size/color variant to a product")
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        variantGroup.MapPut("/{variantId:guid}", async Task<Results<Ok<ProductVariantResponse>, NotFound>> (
            Guid productId,
            Guid variantId,
            ProductVariantRequest request,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var variant = await catalog.UpdateProductVariantAsync(productId, variantId, request, cancellationToken);
            return variant is null ? TypedResults.NotFound() : TypedResults.Ok(variant);
        })
        .WithName("UpdateProductVariant")
        .WithSummary("Update variant details and stock quantity")
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        variantGroup.MapDelete("/{variantId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid productId,
            Guid variantId,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
                await catalog.DeleteProductVariantAsync(productId, variantId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("DeleteProductVariant")
            .WithSummary("Delete a product variant")
            .RequireAuthorization(ApplicationRoles.CatalogManagement);

        return endpoints;
    }
}
