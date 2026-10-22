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
            .WithTags("Shopping cart")
            .RequireAuthorization();

        cart.MapGet("/", async Task<Ok<CartResponse>> (
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await shopping.GetCartAsync(GetUserId(user), cancellationToken)))
            .WithName("GetMyCart")
            .WithSummary("Get the current user's cart");

        cart.MapPost("/items", async Task<Ok<CartResponse>> (
            AddCartItemRequest request,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await shopping.AddCartItemAsync(
                    GetUserId(user), request, cancellationToken)))
            .WithName("AddMyCartItem")
            .WithSummary("Add a product variant to the current user's cart");

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
        .WithSummary("Replace the quantity of one of the current user's cart items");

        cart.MapDelete("/items/{itemId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid itemId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await shopping.RemoveCartItemAsync(GetUserId(user), itemId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("RemoveMyCartItem")
            .WithSummary("Remove one of the current user's cart items");

        var favorites = endpoints.MapGroup("/api/favorites")
            .WithTags("Favorites")
            .RequireAuthorization();

        favorites.MapGet("/", async Task<Ok<IReadOnlyList<FavoriteProductResponse>>> (
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await shopping.GetFavoritesAsync(GetUserId(user), cancellationToken)))
            .WithName("GetMyFavorites")
            .WithSummary("List favorite products for the current user");

        favorites.MapPut("/{productId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid productId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await shopping.AddFavoriteAsync(GetUserId(user), productId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("AddMyFavorite")
            .WithSummary("Add an active product to the current user's favorites");

        favorites.MapDelete("/{productId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid productId,
            IShoppingService shopping,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await shopping.RemoveFavoriteAsync(GetUserId(user), productId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("RemoveMyFavorite")
            .WithSummary("Remove a product from the current user's favorites");

        var orders = endpoints.MapGroup("/api/orders")
            .WithTags("Orders")
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
        .WithSummary("List orders belonging to the current user");

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
        .WithSummary("Get one order belonging to the current user");

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
        .WithSummary("Create an order from the current user's cart")
        .WithDescription("Uses current sale prices, snapshots item details, and decrements stock transactionally.");

        return endpoints;
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var subject = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.TryParse(subject, out var userId)
            ? userId
            : throw new InvalidOperationException("Authenticated token does not contain a valid user identifier.");
    }
}
