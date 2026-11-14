using System.Text.Json;

namespace BigFit.Application.Shopping;

/// <summary>
/// Delivery address captured at checkout. Shared by the customer and staff
/// order responses so both can show the map and the delivery details.
/// </summary>
public sealed record ShipmentAddress(
    string? RecipientName,
    string? PhoneNumber,
    string? AddressLine,
    string? City,
    string? Province,
    string? PostalCode,
    string? CountryCode,
    double? Latitude,
    double? Longitude);

/// <summary>Reads the JSON address snapshot written at checkout.</summary>
public static class ShipmentAddressSnapshot
{
    /// <summary>
    /// Returns null for a missing or malformed snapshot: a bad snapshot must
    /// never break the order list, the queue, or an IPN.
    /// </summary>
    public static ShipmentAddress? Read(string? snapshot)
    {
        if (string.IsNullOrWhiteSpace(snapshot))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(snapshot);
            if (document.RootElement.ValueKind != JsonValueKind.Object)
            {
                return null;
            }

            var properties = new Dictionary<string, JsonElement>(StringComparer.OrdinalIgnoreCase);
            foreach (var property in document.RootElement.EnumerateObject())
            {
                properties[property.Name] = property.Value;
            }

            return new ShipmentAddress(
                Text(properties, nameof(ShipmentAddress.RecipientName)),
                Text(properties, nameof(ShipmentAddress.PhoneNumber)),
                Text(properties, nameof(ShipmentAddress.AddressLine)),
                Text(properties, nameof(ShipmentAddress.City)),
                Text(properties, nameof(ShipmentAddress.Province)),
                Text(properties, nameof(ShipmentAddress.PostalCode)),
                Text(properties, nameof(ShipmentAddress.CountryCode)),
                Number(properties, nameof(ShipmentAddress.Latitude)),
                Number(properties, nameof(ShipmentAddress.Longitude)));
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static string? Text(
        IReadOnlyDictionary<string, JsonElement> properties,
        string name) =>
        properties.TryGetValue(name, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static double? Number(
        IReadOnlyDictionary<string, JsonElement> properties,
        string name) =>
        properties.TryGetValue(name, out var value) &&
            value.ValueKind == JsonValueKind.Number &&
            value.TryGetDouble(out var number)
            ? number
            : null;
}
