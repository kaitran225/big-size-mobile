using BigFit.Application.Assistant;
using BigFit.Application.Addresses;
using BigFit.Application.Catalog;
using BigFit.Application.Notifications;
using BigFit.Application.Shopping;

namespace BigFit.Application.Abstractions;

/// <summary>Own-user cart, favorites, and order operations.</summary>
public interface IShoppingService
{
    Task<CartResponse> GetCartAsync(Guid userId, CancellationToken cancellationToken);
    Task<CartResponse> AddCartItemAsync(Guid userId, AddCartItemRequest request, CancellationToken cancellationToken);
    Task<CartResponse?> UpdateCartItemAsync(Guid userId, Guid itemId, UpdateCartItemRequest request, CancellationToken cancellationToken);
    Task<bool> RemoveCartItemAsync(Guid userId, Guid itemId, CancellationToken cancellationToken);
    Task<IReadOnlyList<FavoriteProductResponse>> GetFavoritesAsync(Guid userId, CancellationToken cancellationToken);
    Task<bool> AddFavoriteAsync(Guid userId, Guid productId, CancellationToken cancellationToken);
    Task<bool> RemoveFavoriteAsync(Guid userId, Guid productId, CancellationToken cancellationToken);
    Task<OrderResponse> CreateOrderAsync(Guid userId, CreateOrderRequest request, CancellationToken cancellationToken);
    Task<OrderResponse?> GetOrderAsync(Guid userId, Guid orderId, CancellationToken cancellationToken);
    Task<PagedResponse<OrderResponse>> GetOrdersAsync(Guid userId, int page, int pageSize, CancellationToken cancellationToken);
}

/// <summary>Delivery-address operations scoped to the authenticated user.</summary>
public interface IAddressService
{
    Task<IReadOnlyList<CustomerAddressResponse>> GetMineAsync(Guid userId, CancellationToken cancellationToken);
    Task<CustomerAddressResponse> CreateAsync(Guid userId, CustomerAddressRequest request, CancellationToken cancellationToken);
    Task<CustomerAddressResponse?> UpdateAsync(Guid userId, Guid addressId, CustomerAddressRequest request, CancellationToken cancellationToken);
    Task<bool> DeleteAsync(Guid userId, Guid addressId, CancellationToken cancellationToken);
}

/// <summary>Provider-neutral extension point for payment initiation and callbacks.</summary>
public interface IPaymentService;

/// <summary>Own-user notification operations.</summary>
public interface INotificationService
{
    Task<PagedResponse<UserNotificationResponse>> GetMineAsync(
        Guid userId, int page, int pageSize, CancellationToken cancellationToken);
    Task<UserNotificationResponse> CreateForUserAsync(
        Guid userId, CreateNotificationRequest request, CancellationToken cancellationToken);
    Task<bool> MarkReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
    Task<bool> DeleteAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
}

/// <summary>Provider-neutral BigFit catalogue and size assistant.</summary>
public interface IChatAssistantService
{
    Task<ChatAssistantResponse> AskAsync(
        ChatAssistantRequest request, CancellationToken cancellationToken);
}

/// <summary>Publishes notification changes to connected clients.</summary>
public interface INotificationEventPublisher
{
    Task PublishCreatedAsync(Guid userId, UserNotificationResponse notification, CancellationToken cancellationToken);
    Task PublishReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
    Task PublishDeletedAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
}

/// <summary>Extension point for email verification and password-reset delivery.</summary>
public interface IEmailVerificationService;

/// <summary>Extension point for expiring, rate-limited one-time codes.</summary>
public interface IOtpService;

/// <summary>Extension point for delivery addresses and map-provider integration.</summary>
public interface IMapLocationService;
