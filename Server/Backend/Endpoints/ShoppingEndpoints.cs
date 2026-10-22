using System.Security.Claims;
using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using BigFit.Application.Shopping;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class ShoppingEndpoints
{
    public static IEndpointRouteBuilder MapShoppingEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var cart = endpoints.MapGroup("/api/cart")
            .WithTags(ApiMessages.TagShoppingCart)
            .RequireAuthorization();

        cart.MapGet("/", async Task<Ok<CartResponse>> (
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await shopping.GetCartAsync(GetUserId(user), cancellationToken)))
            .WithName("GetMyCart")
            .WithSummary(ApiMessages.SummaryGetMyCart);

        cart.MapPost("/items", async Task<Ok<CartResponse>> (
            AddCartItemRequest request,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await shopping.AddCartItemAsync(
                    GetUserId(user), request, cancellationToken)))
            .WithName("AddMyCartItem")
            .WithSummary(ApiMessages.SummaryAddMyCartItem);

        cart.MapPut("/items/{itemId:guid}", async Task<Results<Ok<CartResponse>, NotFound>> (
            Guid itemId,
            UpdateCartItemRequest request,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var cartResponse = await shopping.UpdateCartItemAsync(
                GetUserId(user), itemId, request, cancellationToken);
            return cartResponse is null ? TypedResults.NotFound() : TypedResults.Ok(cartResponse);
        })
        .WithName("UpdateMyCartItem")
        .WithSummary(ApiMessages.SummaryUpdateMyCartItem);

        cart.MapDelete("/items/{itemId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid itemId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await shopping.RemoveCartItemAsync(GetUserId(user), itemId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("RemoveMyCartItem")
            .WithSummary(ApiMessages.SummaryRemoveMyCartItem);

        var favorites = endpoints.MapGroup("/api/favorites")
            .WithTags(ApiMessages.TagFavorites)
            .RequireAuthorization();

        favorites.MapGet("/", async Task<Ok<IReadOnlyList<FavoriteProductResponse>>> (
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await shopping.GetFavoritesAsync(GetUserId(user), cancellationToken)))
            .WithName("GetMyFavorites")
            .WithSummary(ApiMessages.SummaryGetMyFavorites);

        favorites.MapPut("/{productId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid productId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await shopping.AddFavoriteAsync(GetUserId(user), productId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("AddMyFavorite")
            .WithSummary(ApiMessages.SummaryAddMyFavorite);

        favorites.MapDelete("/{productId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid productId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await shopping.RemoveFavoriteAsync(GetUserId(user), productId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("RemoveMyFavorite")
            .WithSummary(ApiMessages.SummaryRemoveMyFavorite);

        var orders = endpoints.MapGroup("/api/orders")
            .WithTags(ApiMessages.TagOrders)
            .RequireAuthorization();

        orders.MapGet("/", async Task<Results<Ok<PagedResponse<OrderResponse>>, BadRequest>> (
            IShoppingService shopping,
            ClaimsPrincipal user,
            int? page,
            int? pageSize,
            CancellationToken cancellationToken) =>
        {
            var requestedPage = page ?? 1;
            var requestedPageSize = pageSize ?? 20;
            if (requestedPage < 1 || requestedPageSize is < 1 or > 100)
            {
                return TypedResults.BadRequest();
            }

            return TypedResults.Ok(await shopping.GetOrdersAsync(
                GetUserId(user), requestedPage, requestedPageSize, cancellationToken));
        })
        .WithName("GetMyOrders")
        .WithSummary(ApiMessages.SummaryGetMyOrders);

        orders.MapGet("/{orderId:guid}", async Task<Results<Ok<OrderResponse>, NotFound>> (
            Guid orderId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var order = await shopping.GetOrderAsync(GetUserId(user), orderId, cancellationToken);
            return order is null ? TypedResults.NotFound() : TypedResults.Ok(order);
        })
        .WithName("GetMyOrder")
        .WithSummary(ApiMessages.SummaryGetMyOrder);

        orders.MapPost("/", async Task<Created<OrderResponse>> (
            CreateOrderRequest request,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var order = await shopping.CreateOrderAsync(GetUserId(user), request, cancellationToken);
            return TypedResults.Created($"/api/orders/{order.Id}", order);
        })
        .WithName("CreateMyOrder")
        .WithSummary(ApiMessages.SummaryCreateMyOrder)
        .WithDescription(ApiMessages.DescriptionCreateMyOrder);

        return endpoints;
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var subject = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.TryParse(subject, out var userId)
            ? userId
            : throw new InvalidOperationException(ApiMessages.AuthenticatedTokenWithoutUserId);
    }
}
