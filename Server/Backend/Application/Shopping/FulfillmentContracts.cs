using System.ComponentModel.DataAnnotations;
using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;

namespace BigFit.Application.Shopping;

/// <summary>Staff-visible order with customer and payment summary.</summary>
public sealed record StaffOrderResponse(
    Guid Id,
    string OrderNumber,
    string Status,
    decimal Subtotal,
    decimal ShippingAmount,
    decimal TotalAmount,
    string CurrencyCode,
    string? RejectionReason,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    Guid CustomerId,
    string CustomerDisplayName,
    string CustomerEmail,
    string? PaymentMethod,
    string? PaymentStatus,
    IReadOnlyList<OrderItemResponse> Items);

/// <summary>Request to advance an order through fulfilment.</summary>
public sealed record FulfillmentActionRequest : IValidatableObject
{
    [Required, RegularExpression("^(accept|ship|complete|reject)$")]
    public required string Action { get; init; }

    [StringLength(500)]
    public string? Reason { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Action == "reject" && string.IsNullOrWhiteSpace(Reason))
        {
            yield return new ValidationResult(
                ApiMessages.RejectionReasonRequired,
                [nameof(Reason)]);
        }
    }
}

/// <summary>Realtime payload when an order status changes.</summary>
public sealed record OrderStatusChangedEvent(Guid OrderId, string Status, DateTimeOffset UpdatedAt);
