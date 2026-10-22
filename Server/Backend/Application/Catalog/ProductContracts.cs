using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Catalog;

/// <summary>Input for a product size and color variant.</summary>
public sealed record ProductVariantRequest
{
    [Required, MaxLength(80)]
    public required string Sku { get; init; }

    [Required, MaxLength(40)]
    public required string Size { get; init; }

    [Required, MaxLength(60)]
    public required string Color { get; init; }

    [Range(0, int.MaxValue)]
    public int StockQuantity { get; init; }
}

/// <summary>Input for creating a catalogue product.</summary>
public sealed record CreateProductRequest
{
    [Required, MaxLength(200)]
    public required string Name { get; init; }

    [MaxLength(4000)]
    public string? Description { get; init; }

    [Range(typeof(decimal), "0.01", "999999999")]
    public decimal Price { get; init; }

    [Range(typeof(decimal), "0.01", "999999999")]
    public decimal? SalePrice { get; init; }

    [Required, RegularExpression("^[A-Z]{3}$")]
    public string CurrencyCode { get; init; } = "EUR";

    [Url, MaxLength(2048)]
    public string? ImageUrl { get; init; }

    public required Guid CategoryId { get; init; }
    public bool IsActive { get; init; } = true;
    public IReadOnlyList<ProductVariantRequest> Variants { get; init; } = [];
}

/// <summary>Input for replacing a catalogue product.</summary>
public sealed record UpdateProductRequest
{
    [Required, MaxLength(200)]
    public required string Name { get; init; }

    [MaxLength(4000)]
    public string? Description { get; init; }

    [Range(typeof(decimal), "0.01", "999999999")]
    public decimal Price { get; init; }

    [Range(typeof(decimal), "0.01", "999999999")]
    public decimal? SalePrice { get; init; }

    [Required, RegularExpression("^[A-Z]{3}$")]
    public string CurrencyCode { get; init; } = "EUR";

    [Url, MaxLength(2048)]
    public string? ImageUrl { get; init; }

    public required Guid CategoryId { get; init; }
    public bool IsActive { get; init; }
    public IReadOnlyList<ProductVariantRequest> Variants { get; init; } = [];
}

/// <summary>A size and color option with its current stock quantity.</summary>
public sealed record ProductVariantResponse(
    Guid Id,
    string Sku,
    string Size,
    string Color,
    int StockQuantity);

/// <summary>A catalogue product and its available variants.</summary>
public sealed record ProductResponse(
    Guid Id,
    string Name,
    string? Description,
    decimal Price,
    decimal? SalePrice,
    decimal CurrentPrice,
    bool IsOnSale,
    string CurrencyCode,
    string? ImageUrl,
    bool IsActive,
    Guid CategoryId,
    DateTimeOffset CreatedAt,
    IReadOnlyList<ProductVariantResponse> Variants);
