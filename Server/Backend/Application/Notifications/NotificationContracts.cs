using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Notifications;

/// <summary>Input to create a notification for the authenticated user.</summary>
public sealed record CreateNotificationRequest
{
    [Required, MaxLength(40)]
    public required string Type { get; init; }

    [Required, MinLength(1), MaxLength(160)]
    public required string Title { get; init; }

    [Required, MinLength(1), MaxLength(2000)]
    public required string Message { get; init; }

    [MaxLength(4000)]
    public string? DataJson { get; init; }
}

/// <summary>A notification belonging to one user.</summary>
public sealed record UserNotificationResponse(
    Guid Id,
    string Type,
    string Title,
    string Message,
    string? DataJson,
    DateTimeOffset CreatedAt,
    DateTimeOffset? ReadAt);
