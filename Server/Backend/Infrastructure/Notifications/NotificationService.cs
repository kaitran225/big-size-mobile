using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using BigFit.Application.Notifications;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Notifications;

internal sealed class NotificationService(
    BigFitDbContext dbContext,
    INotificationEventPublisher eventPublisher) : INotificationService
{
    public async Task<PagedResponse<UserNotificationResponse>> GetMineAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var query = dbContext.Notifications.AsNoTracking()
            .Where(notification => notification.UserId == userId)
            .OrderByDescending(notification => notification.CreatedAt);
        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query.Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(notification => ToResponse(notification))
            .ToListAsync(cancellationToken);
        return new PagedResponse<UserNotificationResponse>(
            items,
            page,
            pageSize,
            totalCount,
            (int)Math.Ceiling(totalCount / (double)pageSize));
    }

    public async Task<UserNotificationResponse> CreateForUserAsync(
        Guid userId,
        CreateNotificationRequest request,
        CancellationToken cancellationToken)
    {
        if (request.DataJson is not null)
        {
            try
            {
                using var _ = System.Text.Json.JsonDocument.Parse(request.DataJson);
            }
            catch (System.Text.Json.JsonException exception)
            {
                throw new ArgumentException(ApiMessages.InvalidNotificationData, nameof(request), exception);
            }
        }

        var notification = new UserNotification
        {
            UserId = userId,
            Type = request.Type.Trim(),
            Title = request.Title.Trim(),
            Message = request.Message.Trim(),
            DataJson = request.DataJson
        };
        dbContext.Notifications.Add(notification);
        await dbContext.SaveChangesAsync(cancellationToken);

        var response = ToResponse(notification);
        await eventPublisher.PublishCreatedAsync(userId, response, cancellationToken);
        return response;
    }

    public async Task<bool> MarkReadAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken)
    {
        var notification = await dbContext.Notifications.SingleOrDefaultAsync(
            item => item.UserId == userId && item.Id == notificationId,
            cancellationToken);
        if (notification is null)
        {
            return false;
        }

        if (notification.ReadAt is null)
        {
            notification.ReadAt = DateTimeOffset.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        await eventPublisher.PublishReadAsync(userId, notificationId, cancellationToken);
        return true;
    }

    public async Task<bool> DeleteAsync(
        Guid userId,
        Guid notificationId,
        CancellationToken cancellationToken)
    {
        var notification = await dbContext.Notifications.SingleOrDefaultAsync(
            item => item.UserId == userId && item.Id == notificationId,
            cancellationToken);
        if (notification is null)
        {
            return false;
        }

        dbContext.Notifications.Remove(notification);
        await dbContext.SaveChangesAsync(cancellationToken);
        await eventPublisher.PublishDeletedAsync(userId, notificationId, cancellationToken);
        return true;
    }

    private static UserNotificationResponse ToResponse(UserNotification notification) =>
        new(
            notification.Id,
            notification.Type,
            notification.Title,
            notification.Message,
            notification.DataJson,
            notification.CreatedAt,
            notification.ReadAt);
}
