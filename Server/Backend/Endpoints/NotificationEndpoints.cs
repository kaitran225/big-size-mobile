using System.Security.Claims;
using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using BigFit.Application.Notifications;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class NotificationEndpoints
{
    public static IEndpointRouteBuilder MapNotificationEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/notifications")
            .WithTags("Notifications")
            .RequireAuthorization();

        group.MapGet("/", async Task<Results<Ok<PagedResponse<UserNotificationResponse>>, BadRequest>> (
            INotificationService notifications,
            ClaimsPrincipal user,
            int? page,
            int? pageSize,
            CancellationToken cancellationToken) =>
        {
            var requestedPage = page ?? 1;
            var requestedPageSize = pageSize ?? 30;
            if (requestedPage < 1 || requestedPageSize is < 1 or > 100)
            {
                return TypedResults.BadRequest();
            }

            if (!TryGetUserId(user, out var userId))
            {
                return TypedResults.BadRequest();
            }

            return TypedResults.Ok(await notifications.GetMineAsync(
                userId, requestedPage, requestedPageSize, cancellationToken));
        })
        .WithName("GetMyNotifications")
        .WithSummary("List notifications belonging to the current user");

        group.MapPost("/", async Task<Results<Created<UserNotificationResponse>, BadRequest>> (
            CreateNotificationRequest request,
            INotificationService notifications,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            if (!TryGetUserId(user, out var userId))
            {
                return TypedResults.BadRequest();
            }

            var created = await notifications.CreateForUserAsync(userId, request, cancellationToken);
            return TypedResults.Created($"/api/notifications/{created.Id}", created);
        })
        .WithName("CreateMyNotification")
        .WithSummary("Create a notification for the current user");

        group.MapPut("/{id:guid}/read", async Task<Results<NoContent, NotFound>> (
            Guid id,
            INotificationService notifications,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            if (!TryGetUserId(user, out var userId) ||
                !await notifications.MarkReadAsync(userId, id, cancellationToken))
            {
                return TypedResults.NotFound();
            }

            return TypedResults.NoContent();
        })
        .WithName("MarkMyNotificationRead")
        .WithSummary("Mark one of the current user's notifications as read");

        group.MapDelete("/{id:guid}", async Task<Results<NoContent, NotFound>> (
            Guid id,
            INotificationService notifications,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            if (!TryGetUserId(user, out var userId) ||
                !await notifications.DeleteAsync(userId, id, cancellationToken))
            {
                return TypedResults.NotFound();
            }

            return TypedResults.NoContent();
        })
        .WithName("DeleteMyNotification")
        .WithSummary("Delete one of the current user's notifications");

        return endpoints;
    }

    private static bool TryGetUserId(ClaimsPrincipal user, out Guid userId)
    {
        var subject = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.TryParse(subject, out userId);
    }
}
