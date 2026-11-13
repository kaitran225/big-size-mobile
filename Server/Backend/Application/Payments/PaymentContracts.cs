using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace BigFit.Application.Payments;

/// <summary>The Bank Hub account a shopper transfers money to.</summary>
public sealed record SepayBankAccountResponse(
    string BankCode,
    string BankBin,
    string AccountNumber,
    string AccountHolderName);

/// <summary>What the running server knows about its Bank Hub sandbox setup. Never contains secrets.</summary>
public sealed record SepaySandboxStatusResponse(
    string Mode,
    bool HasClientId,
    bool HasClientSecret,
    bool HasIpnSecretKey,
    bool HasBankAccountXid,
    string ApiBaseUrl,
    string? NotifyUrl,
    string? LinkedBankAccountXid,
    string? BankCode,
    string? AccountNumber,
    string? AccountHolderName,
    string? Error);

/// <summary>A payment attempt. Bank Hub sessions carry the bank code and transfer content in CheckoutFields.</summary>
public sealed record PaymentSessionResponse(
    Guid Id,
    Guid OrderId,
    string Provider,
    string Method,
    string Status,
    decimal Amount,
    string CurrencyCode,
    string? ProviderReference,
    string? CheckoutUrl,
    IReadOnlyDictionary<string, string>? CheckoutFields);

/// <summary>JSON body SePay posts to the IPN endpoint.</summary>
public sealed class SepayIpnPayload
{
    [JsonPropertyName("notification_type")]
    public string? NotificationType { get; init; }

    [JsonPropertyName("order")]
    public SepayIpnOrder? Order { get; init; }

    [JsonPropertyName("transaction")]
    public SepayIpnTransaction? Transaction { get; init; }

    [JsonPropertyName("payment_code")]
    public string? PaymentCode { get; init; }

    [JsonPropertyName("content")]
    public string? Content { get; init; }

    [JsonPropertyName("transfer_type")]
    public string? TransferType { get; init; }

    [JsonPropertyName("amount")]
    [JsonConverter(typeof(JsonScalarConverter))]
    public string? Amount { get; init; }

    [JsonPropertyName("transaction_id")]
    [JsonConverter(typeof(JsonScalarConverter))]
    public string? TransactionId { get; init; }
}

/// <summary>Order section of a SePay IPN.</summary>
public sealed class SepayIpnOrder
{
    [JsonPropertyName("order_invoice_number")]
    public string? OrderInvoiceNumber { get; init; }

    [JsonPropertyName("order_amount")]
    [JsonConverter(typeof(JsonScalarConverter))]
    public string? OrderAmount { get; init; }

    [JsonPropertyName("order_currency")]
    public string? OrderCurrency { get; init; }
}

/// <summary>Transaction section of a SePay IPN.</summary>
public sealed class SepayIpnTransaction
{
    [JsonPropertyName("id")]
    [JsonConverter(typeof(JsonScalarConverter))]
    public string? Id { get; init; }

    [JsonPropertyName("transaction_id")]
    [JsonConverter(typeof(JsonScalarConverter))]
    public string? TransactionId { get; init; }

    [JsonPropertyName("transaction_amount")]
    [JsonConverter(typeof(JsonScalarConverter))]
    public string? TransactionAmount { get; init; }
}

/// <summary>Reads a JSON string or number into one string so endpoint validation can accept both.</summary>
public sealed class JsonScalarConverter : JsonConverter<string?>
{
    public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options) =>
        reader.TokenType switch
        {
            JsonTokenType.String => reader.GetString(),
            JsonTokenType.Number => Encoding.UTF8.GetString(reader.ValueSpan),
            JsonTokenType.Null => null,
            _ => throw new JsonException("A payment amount or id must be a string or number.")
        };

    public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options)
    {
        if (value is null)
        {
            writer.WriteNullValue();
            return;
        }

        writer.WriteStringValue(value);
    }
}

/// <summary>Acknowledgement body SePay requires from an IPN endpoint.</summary>
public sealed record SepayAck(bool Success);
