using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using BigFit.Application.Authentication;

namespace BigFit.Api.Endpoints;

public static class CategoryEndpoints
{
    public static IEndpointRouteBuilder MapCategoryEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/categories").WithTags(ApiMessages.TagCategories);

        group.MapGet("/", async Task<Ok<IReadOnlyList<CategoryResponse>>> (
            ICatalogService catalog,
            string? gender,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await catalog.GetCategoriesAsync(gender, cancellationToken)))
            .WithName("GetCategories")
            .WithSummary(ApiMessages.SummaryGetCategories);

        group.MapGet("/{id:guid}", async Task<Results<Ok<CategoryResponse>, NotFound>> (
            Guid id,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var category = await catalog.GetCategoryAsync(id, cancellationToken);
            return category is null ? TypedResults.NotFound() : TypedResults.Ok(category);
        })
        .WithName("GetCategory")
        .WithSummary(ApiMessages.SummaryGetCategory);

        group.MapPost("/", async Task<Created<CategoryResponse>> (
            CreateCategoryRequest request,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var category = await catalog.CreateCategoryAsync(request, cancellationToken);
            return TypedResults.Created($"/api/categories/{category.Id}", category);
        })
        .WithName("CreateCategory")
        .WithSummary(ApiMessages.SummaryCreateCategory)
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        group.MapPut("/{id:guid}", async Task<Results<Ok<CategoryResponse>, NotFound>> (
            Guid id,
            UpdateCategoryRequest request,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var category = await catalog.UpdateCategoryAsync(id, request, cancellationToken);
            return category is null ? TypedResults.NotFound() : TypedResults.Ok(category);
        })
        .WithName("UpdateCategory")
        .WithSummary(ApiMessages.SummaryUpdateCategory)
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        group.MapDelete("/{id:guid}", async Task<Results<NoContent, NotFound, Conflict<ProblemDetails>>> (
            Guid id,
            ICatalogService catalog,
            CancellationToken cancellationToken) =>
        {
            var result = await catalog.DeleteCategoryAsync(id, cancellationToken);
            return result switch
            {
                0 => TypedResults.NotFound(),
                1 => TypedResults.NoContent(),
                _ => TypedResults.Conflict(new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = ApiMessages.CategoryContainsProductsTitle,
                    Detail = ApiMessages.CategoryContainsProductsDetail
                })
            };
        })
        .WithName("DeleteCategory")
        .WithSummary(ApiMessages.SummaryDeleteCategory)
        .RequireAuthorization(ApplicationRoles.CatalogManagement);

        return endpoints;
    }
}
