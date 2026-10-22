using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Shopping;

/// <summary>Input to add a product variant to the current user's cart.</summary>
public sealed record AddCartItemRequest
{
    [Required]
    public required Guid ProductVariantId { get; init; }

    [Range(1, 50)]
    public int Quantity { get; init; } = 1;
}

/// <summary>Input to replace the quantity of a cart line.</summary>
public sealed record UpdateCartItemRequest
{
    [Range(1, 50)]
    public int Quantity { get; init; }
}

/// <summary>Input to create an order from the current user's cart.</summary>
public sealed record CreateOrderRequest
{
    public Guid? ShippingAddressId { get; init; }
}

/// <summary>A product variant and its current price/stock in a cart.</summary>
public sealed record CartItemResponse(
    Guid Id,
    Guid ProductId,
    string ProductName,
    Guid ProductVariantId,
    string Sku,
    string Size,
    string Color,
    int Quantity,
    int StockQuantity,
    decimal UnitPrice,
    decimal LineTotal,
    string CurrencyCode,
    string? ImageUrl);

/// <summary>The current user's cart.</summary>
public sealed record CartResponse(Guid? Id, IReadOnlyList<CartItemResponse> Items);

/// <summary>A favorited product summary.</summary>
public sealed record FavoriteProductResponse(
    Guid ProductId,
    string Name,
    decimal Price,
    decimal? SalePrice,
    decimal CurrentPrice,
    bool IsOnSale,
    string CurrencyCode,
    string? ImageUrl,
    Guid CategoryId);

/// <summary>A line item captured as an order-time price and product snapshot.</summary>
public sealed record OrderItemResponse(
    Guid Id,
    string ProductName,
    string Sku,
    string Size,
    string Color,
    int Quantity,
    decimal UnitPrice,
    decimal LineTotal);

/// <summary>An order belonging to the authenticated customer.</summary>
public sealed record OrderResponse(
    Guid Id,
    string OrderNumber,
    string Status,
    decimal Subtotal,
    decimal ShippingAmount,
    decimal TotalAmount,
    string CurrencyCode,
    DateTimeOffset CreatedAt,
    IReadOnlyList<OrderItemResponse> Items);
