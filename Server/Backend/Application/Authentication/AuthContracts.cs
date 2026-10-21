using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Authentication;

/// <summary>Creates a customer account.</summary>
public sealed record RegisterCustomerRequest
{
    [Required, EmailAddress, MaxLength(254)]
    public required string Email { get; init; }

    [Required, MinLength(2), MaxLength(120)]
    public required string DisplayName { get; init; }

    [Required, MinLength(12), MaxLength(128)]
    public required string Password { get; init; }
}

/// <summary>Authenticates an existing account.</summary>
public sealed record LoginRequest
{
    [Required, EmailAddress, MaxLength(254)]
    public required string Email { get; init; }

    [Required, MaxLength(128)]
    public required string Password { get; init; }
}

/// <summary>Creates a store staff account; only administrators may submit this request.</summary>
public sealed record CreateStoreStaffRequest
{
    [Required, EmailAddress, MaxLength(254)]
    public required string Email { get; init; }

    [Required, MinLength(2), MaxLength(120)]
    public required string DisplayName { get; init; }

    [Required, MinLength(12), MaxLength(128)]
    public required string TemporaryPassword { get; init; }
}

/// <summary>Contains a signed access token and the authenticated user's roles.</summary>
public sealed record AuthResponse(
    string AccessToken,
    DateTimeOffset ExpiresAt,
    string Email,
    string DisplayName,
    IReadOnlyList<string> Roles);

/// <summary>Identifies a newly provisioned store staff account.</summary>
public sealed record UserResponse(Guid Id, string Email, string DisplayName, string Role);

public static class ApplicationRoles
{
    public const string Admin = "Admin";
    public const string StoreStaff = "StoreStaff";
    public const string Customer = "Customer";
    public const string CatalogManagement = Admin + "," + StoreStaff;
}

public sealed class AuthenticationOperationException(
    int statusCode,
    string title,
    string detail) : Exception(detail)
{
    public int StatusCode { get; } = statusCode;
    public string Title { get; } = title;
}
