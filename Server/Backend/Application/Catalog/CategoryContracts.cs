using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Catalog;

/// <summary>Input for creating a product category.</summary>
public sealed record CreateCategoryRequest
{
    [Required, MaxLength(120)]
    public required string Name { get; init; }

    [Required, RegularExpression("^(Men|Women|Unisex)$")]
    public string Gender { get; init; } = "Unisex";

    [MaxLength(1000)]
    public string? Description { get; init; }
}

/// <summary>Input for replacing a product category.</summary>
public sealed record UpdateCategoryRequest
{
    [Required, MaxLength(120)]
    public required string Name { get; init; }

    [Required, RegularExpression("^(Men|Women|Unisex)$")]
    public string Gender { get; init; } = "Unisex";

    [MaxLength(1000)]
    public string? Description { get; init; }
}

/// <summary>A product category returned by the API.</summary>
public sealed record CategoryResponse(Guid Id, string Name, string Gender, string? Description);
