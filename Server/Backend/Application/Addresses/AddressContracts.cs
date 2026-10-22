using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Addresses;

/// <summary>Address details and optional map coordinates for delivery.</summary>
public sealed record CustomerAddressRequest
{
    [Required, MaxLength(80)]
    public required string Label { get; init; }

    [Required, MaxLength(120)]
    public required string RecipientName { get; init; }

    [Required, MaxLength(32)]
    public required string PhoneNumber { get; init; }

    [Required, MaxLength(300)]
    public required string AddressLine { get; init; }

    [Required, MaxLength(120)]
    public required string City { get; init; }

    [MaxLength(120)]
    public string? Province { get; init; }

    [MaxLength(24)]
    public string? PostalCode { get; init; }

    [Required, RegularExpression("^[A-Z]{2}$")]
    public required string CountryCode { get; init; }

    [Range(typeof(decimal), "-90", "90")]
    public decimal? Latitude { get; init; }

    [Range(typeof(decimal), "-180", "180")]
    public decimal? Longitude { get; init; }

    public bool IsDefault { get; init; }
}

/// <summary>A saved delivery address belonging to the current user.</summary>
public sealed record CustomerAddressResponse(
    Guid Id,
    string Label,
    string RecipientName,
    string PhoneNumber,
    string AddressLine,
    string City,
    string? Province,
    string? PostalCode,
    string CountryCode,
    decimal? Latitude,
    decimal? Longitude,
    bool IsDefault,
    DateTimeOffset CreatedAt);
