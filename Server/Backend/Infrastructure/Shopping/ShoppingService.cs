using System.Text.Json;
using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using BigFit.Application.Shopping;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Shopping;

internal sealed class ShoppingService(BigFitDbContext dbContext) : IShoppingService
{
    public async Task<CartResponse> GetCartAsync(Guid userId, CancellationToken cancellationToken)
    {
        var cart = await dbContext.ShoppingCarts.AsNoTracking()
            .Include(item => item.Items)
                .ThenInclude(item => item.ProductVariant)
                    .ThenInclude(variant => variant.Product)
            .SingleOrDefaultAsync(item => item.UserId == userId, cancellationToken);
        return cart is null ? new CartResponse(null, []) : Map(cart);
    }

    public async Task<CartResponse> AddCartItemAsync(
        Guid userId,
        AddCartItemRequest request,
        CancellationToken cancellationToken)
    {
        var variant = await dbContext.ProductVariants
            .Include(item => item.Product)
            .SingleOrDefaultAsync(item => item.Id == request.ProductVariantId, cancellationToken);
        if (variant is null || !variant.Product.IsActive)
        {
            throw new ArgumentException(ApiMessages.VariantNotFound, nameof(request));
        }

        var cart = await dbContext.ShoppingCarts.SingleOrDefaultAsync(
            item => item.UserId == userId, cancellationToken);
        if (cart is null)
        {
            cart = new ShoppingCart { UserId = userId };
            dbContext.ShoppingCarts.Add(cart);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        var cartItem = await dbContext.ShoppingCartItems.SingleOrDefaultAsync(
            item => item.CartId == cart.Id && item.ProductVariantId == variant.Id,
            cancellationToken);
        var requestedQuantity = request.Quantity + (cartItem?.Quantity ?? 0);
        if (requestedQuantity > variant.StockQuantity)
        {
            throw new ArgumentException(ApiMessages.QuantityExceedsStock, nameof(request));
        }

        if (cartItem is null)
        {
            cartItem = new ShoppingCartItem
            {
                CartId = cart.Id,
                ProductVariantId = variant.Id,
                Quantity = request.Quantity
            };
            dbContext.ShoppingCartItems.Add(cartItem);
        }
        else
        {
            cartItem.Quantity = requestedQuantity;
        }

        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetCartAsync(userId, cancellationToken);
    }

    public async Task<CartResponse?> UpdateCartItemAsync(
        Guid userId,
        Guid itemId,
        UpdateCartItemRequest request,
        CancellationToken cancellationToken)
    {
        var item = await dbContext.ShoppingCartItems
            .Include(cartItem => cartItem.Cart)
            .Include(cartItem => cartItem.ProductVariant)
            .SingleOrDefaultAsync(
                cartItem => cartItem.Id == itemId && cartItem.Cart.UserId == userId,
                cancellationToken);
        if (item is null)
        {
            return null;
        }

        if (request.Quantity > item.ProductVariant.StockQuantity)
        {
            throw new ArgumentException(ApiMessages.QuantityExceedsStock, nameof(request));
        }

        item.Quantity = request.Quantity;
        item.Cart.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetCartAsync(userId, cancellationToken);
    }

    public async Task<bool> RemoveCartItemAsync(
        Guid userId,
        Guid itemId,
        CancellationToken cancellationToken)
    {
        var deleted = await dbContext.ShoppingCartItems
            .Where(item => item.Id == itemId && item.Cart.UserId == userId)
            .ExecuteDeleteAsync(cancellationToken);
        return deleted > 0;
    }

    public async Task<IReadOnlyList<FavoriteProductResponse>> GetFavoritesAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await dbContext.FavoriteProducts.AsNoTracking()
            .Where(favorite => favorite.UserId == userId)
            .Join(
                dbContext.Products.AsNoTracking(),
                favorite => favorite.ProductId,
                product => product.Id,
                (favorite, product) => product)
            .OrderBy(product => product.Name)
            .Select(product => new FavoriteProductResponse(
                product.Id,
                product.Name,
                product.Price,
                product.SalePrice,
                product.SalePrice ?? product.Price,
                product.IsOnSale,
                product.CurrencyCode,
                product.ImageUrl,
                product.CategoryId))
            .ToListAsync(cancellationToken);

    public async Task<bool> AddFavoriteAsync(
        Guid userId,
        Guid productId,
        CancellationToken cancellationToken)
    {
        if (!await dbContext.Products.AnyAsync(
                product => product.Id == productId && product.IsActive,
                cancellationToken))
        {
            return false;
        }

        if (await dbContext.FavoriteProducts.AnyAsync(
                favorite => favorite.UserId == userId && favorite.ProductId == productId,
                cancellationToken))
        {
            return true;
        }

        dbContext.FavoriteProducts.Add(new FavoriteProduct { UserId = userId, ProductId = productId });
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> RemoveFavoriteAsync(
        Guid userId,
        Guid productId,
        CancellationToken cancellationToken)
    {
        var deleted = await dbContext.FavoriteProducts
            .Where(favorite => favorite.UserId == userId && favorite.ProductId == productId)
            .ExecuteDeleteAsync(cancellationToken);
        return deleted > 0;
    }

    public async Task<OrderResponse> CreateOrderAsync(
        Guid userId,
        CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        var cart = await dbContext.ShoppingCarts
            .Include(item => item.Items)
                .ThenInclude(item => item.ProductVariant)
                    .ThenInclude(variant => variant.Product)
            .SingleOrDefaultAsync(item => item.UserId == userId, cancellationToken);
        if (cart is null || cart.Items.Count == 0)
        {
            throw new ArgumentException(ApiMessages.CartEmpty, nameof(request));
        }

        CustomerAddress? address = null;
        if (request.ShippingAddressId.HasValue)
        {
            address = await dbContext.CustomerAddresses.SingleOrDefaultAsync(
                item => item.Id == request.ShippingAddressId.Value && item.UserId == userId,
                cancellationToken);
            if (address is null)
            {
                throw new ArgumentException(ApiMessages.AddressNotOwned, nameof(request));
            }
        }

        var currencies = cart.Items
            .Select(item => item.ProductVariant.Product.CurrencyCode)
            .Distinct(StringComparer.Ordinal)
            .ToArray();
        if (currencies.Length != 1)
        {
            throw new ArgumentException(ApiMessages.MixedCurrencies, nameof(request));
        }

        var orderItems = new List<CustomerOrderItem>(cart.Items.Count);
        foreach (var item in cart.Items)
        {
            var variant = item.ProductVariant;
            var product = variant.Product;
            if (!product.IsActive || item.Quantity > variant.StockQuantity)
            {
                throw new ArgumentException(
                    ApiMessages.QuantityNoLongerAvailable(product.Name),
                    nameof(request));
            }

            var unitPrice = product.SalePrice ?? product.Price;
            orderItems.Add(new CustomerOrderItem
            {
                ProductVariantId = variant.Id,
                ProductName = product.Name,
                Sku = variant.Sku,
                Size = variant.Size,
                Color = variant.Color,
                Quantity = item.Quantity,
                UnitPrice = unitPrice,
                LineTotal = unitPrice * item.Quantity
            });
            variant.StockQuantity -= item.Quantity;
        }

        var subtotal = orderItems.Sum(item => item.LineTotal);
        var order = new CustomerOrder
        {
            OrderNumber = $"BF-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid():N}"[..40],
            UserId = userId,
            ShippingAddressId = address?.Id,
            Status = "Pending",
            Subtotal = subtotal,
            ShippingAmount = 0,
            TotalAmount = subtotal,
            CurrencyCode = currencies[0],
            ShippingAddressSnapshot = address is null ? null : JsonSerializer.Serialize(new
            {
                address.RecipientName,
                address.PhoneNumber,
                address.AddressLine,
                address.City,
                address.Province,
                address.PostalCode,
                address.CountryCode,
                address.Latitude,
                address.Longitude
            }),
            Items = orderItems
        };

        dbContext.Orders.Add(order);
        dbContext.ShoppingCartItems.RemoveRange(cart.Items);
        cart.UpdatedAt = DateTimeOffset.UtcNow;
        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException exception)
        {
            await transaction.RollbackAsync(cancellationToken);
            throw new DataConflictException(
                ApiMessages.StockChangedDuringOrder,
                exception);
        }

        return Map(order);
    }

    public async Task<PagedResponse<OrderResponse>> GetOrdersAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var query = dbContext.Orders.AsNoTracking()
            .Where(order => order.UserId == userId)
            .OrderByDescending(order => order.CreatedAt);
        var totalCount = await query.CountAsync(cancellationToken);
        var orders = await query.Include(order => order.Items)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResponse<OrderResponse>(
            orders.Select(Map).ToArray(),
            page,
            pageSize,
            totalCount,
            (int)Math.Ceiling(totalCount / (double)pageSize));
    }

    public async Task<OrderResponse?> GetOrderAsync(
        Guid userId,
        Guid orderId,
        CancellationToken cancellationToken)
    {
        var order = await dbContext.Orders.AsNoTracking()
            .Include(item => item.Items)
            .SingleOrDefaultAsync(
                item => item.UserId == userId && item.Id == orderId,
                cancellationToken);
        return order is null ? null : Map(order);
    }

    private static CartResponse Map(ShoppingCart cart) =>
        new(cart.Id, cart.Items.Select(item =>
        {
            var product = item.ProductVariant.Product;
            var unitPrice = product.SalePrice ?? product.Price;
            return new CartItemResponse(
                item.Id,
                product.Id,
                product.Name,
                item.ProductVariantId,
                item.ProductVariant.Sku,
                item.ProductVariant.Size,
                item.ProductVariant.Color,
                item.Quantity,
                item.ProductVariant.StockQuantity,
                unitPrice,
                unitPrice * item.Quantity,
                product.CurrencyCode,
                product.ImageUrl);
        }).ToArray());

    private static OrderResponse Map(CustomerOrder order) =>
        new(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.Subtotal,
            order.ShippingAmount,
            order.TotalAmount,
            order.CurrencyCode,
            order.CreatedAt,
            order.Items.Select(item => new OrderItemResponse(
                item.Id,
                item.ProductName,
                item.Sku,
                item.Size,
                item.Color,
                item.Quantity,
                item.UnitPrice,
                item.LineTotal)).ToArray());
}
