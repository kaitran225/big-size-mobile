using BigFit.Application.Abstractions;
using BigFit.Application.Notifications;
using Microsoft.AspNetCore.SignalR;

namespace BigFit.Api.Realtime;

internal sealed class SignalRNotificationEventPublisher(
    IHubContext<NotificationHub> hubContext) : INotificationEventPublisher
{
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
}
