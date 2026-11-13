using BigFit.Application.Assistant;
using BigFit.Application.Addresses;
using BigFit.Application.Catalog;
using BigFit.Application.Notifications;
using BigFit.Application.Payments;
using BigFit.Application.Security;
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

/// <summary>Staff order queue and status transitions.</summary>
public interface IOrderFulfillmentService
{
    Task<PagedResponse<StaffOrderResponse>> GetQueueAsync(
        int page,
        int pageSize,
        bool includeDelivered,
        CancellationToken cancellationToken);

    Task<StaffOrderResponse?> ApplyActionAsync(
        Guid orderId,
        string action,
        Guid staffUserId,
        CancellationToken cancellationToken);
}

/// <summary>Delivery-address operations scoped to the authenticated user.</summary>
public interface IAddressService
{
    Task<IReadOnlyList<CustomerAddressResponse>> GetMineAsync(Guid userId, CancellationToken cancellationToken);
    Task<CustomerAddressResponse> CreateAsync(Guid userId, CustomerAddressRequest request, CancellationToken cancellationToken);
    Task<CustomerAddressResponse?> UpdateAsync(Guid userId, Guid addressId, CustomerAddressRequest request, CancellationToken cancellationToken);
    Task<bool> DeleteAsync(Guid userId, Guid addressId, CancellationToken cancellationToken);
}

/// <summary>Creates a payment for an order and applies SePay sandbox callbacks.</summary>
public interface IPaymentService
{
    Task<PaymentSessionResponse> CreateAsync(
        Guid userId, Guid orderId, string method, CancellationToken cancellationToken);

    Task<PaymentSessionResponse?> GetLatestAsync(
        Guid userId, Guid orderId, CancellationToken cancellationToken);

    Task<PaymentSessionResponse> ReportClientResultAsync(
        Guid userId,
        Guid orderId,
        Guid paymentId,
        string result,
        CancellationToken cancellationToken);

    Task<PaymentSessionResponse> SimulateSandboxPaymentAsync(
        Guid userId,
        Guid orderId,
        Guid paymentId,
        CancellationToken cancellationToken);

    Task<SepayBankAccountResponse> GetLinkedBankAccountAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Applies an IPN. Returns false when the caller secret does not match.
    /// </summary>
    Task<bool> HandleIpnAsync(
        string? secretKey, SepayIpnPayload payload, CancellationToken cancellationToken);
}

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
        ChatAssistantRequest request,
        Guid? userId,
        CancellationToken cancellationToken);
}

/// <summary>Publishes notification changes to connected clients.</summary>
public interface INotificationEventPublisher
{
    Task PublishCreatedAsync(Guid userId, UserNotificationResponse notification, CancellationToken cancellationToken);
    Task PublishReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
    Task PublishDeletedAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken);
    Task PublishOrderStatusChangedAsync(
        Guid userId,
        OrderStatusChangedEvent change,
        CancellationToken cancellationToken);
    Task PublishStaffEventAsync(string eventName, object payload, CancellationToken cancellationToken);
}

/// <summary>Email verification and password-reset tokens.</summary>
public interface IEmailVerificationService
{
    Task<RequestEmailVerificationResponse> RequestVerificationAsync(
        Guid userId, CancellationToken cancellationToken);
    Task<bool> ConfirmEmailAsync(string token, CancellationToken cancellationToken);
    Task<bool> RequestPasswordResetAsync(string email, CancellationToken cancellationToken);
    Task<bool> CompletePasswordResetAsync(
        string token, string newPassword, CancellationToken cancellationToken);
}

/// <summary>Expiring, rate-limited one-time passcodes.</summary>
public interface IOtpService
{
    Task<OtpRequestResponse> RequestAsync(
        Guid? userId, RequestOtpRequest request, CancellationToken cancellationToken);
    Task<OtpVerifyResponse> VerifyAsync(VerifyOtpRequest request, CancellationToken cancellationToken);
}

/// <summary>Extension point for delivery addresses and map-provider integration.</summary>
public interface IMapLocationService;
