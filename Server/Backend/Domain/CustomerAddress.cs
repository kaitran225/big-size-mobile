namespace BigFit.Domain.Entities;

/// <summary>A delivery address owned by a customer.</summary>
public sealed class CustomerAddress
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public required string Label { get; set; }
    public required string RecipientName { get; set; }
    public required string PhoneNumber { get; set; }
    public required string AddressLine { get; set; }
    public required string City { get; set; }
    public string? Province { get; set; }
    public string? PostalCode { get; set; }
    public required string CountryCode { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public bool IsDefault { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
