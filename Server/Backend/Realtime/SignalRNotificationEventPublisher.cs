using BigFit.Application.Abstractions;
using BigFit.Application.Notifications;
using BigFit.Application.Shopping;
using Microsoft.AspNetCore.SignalR;

namespace BigFit.Api.Realtime;

internal sealed class SignalRNotificationEventPublisher(
    IHubContext<NotificationHub> hubContext) : INotificationEventPublisher
{
    public const string StaffGroupName = "staff";
    public Task PublishCreatedAsync(
        Guid userId,
        UserNotificationResponse notification,
        CancellationToken cancellationToken) =>
        hubContext.Clients.User(userId.ToString())
            .SendAsync("notificationCreated", notification, cancellationToken);

    public Task PublishReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken) =>
        hubContext.Clients.User(userId.ToString())
            .SendAsync("notificationRead", notificationId, cancellationToken);

    public Task PublishDeletedAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken) =>
        hubContext.Clients.User(userId.ToString())
            .SendAsync("notificationDeleted", notificationId, cancellationToken);

    public Task PublishOrderStatusChangedAsync(
        Guid userId,
        OrderStatusChangedEvent change,
        CancellationToken cancellationToken) =>
        hubContext.Clients.User(userId.ToString())
            .SendAsync("orderStatusChanged", change, cancellationToken);

    public Task PublishStaffEventAsync(
        string eventName,
        object payload,
        CancellationToken cancellationToken) =>
        hubContext.Clients.Group(StaffGroupName)
            .SendAsync(eventName, payload, cancellationToken);
}
