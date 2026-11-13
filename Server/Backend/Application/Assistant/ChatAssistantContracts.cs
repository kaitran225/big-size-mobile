using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Assistant;

/// <summary>Single turn message in chat history.</summary>
public sealed record ChatMessageItem(
    [Required, RegularExpression("^(user|assistant)$")] string Role,
    [Required, MaxLength(4000)] string Content);

/// <summary>Question for the BigFit catalogue assistant.</summary>
public sealed record ChatAssistantRequest
{
    [Required, MinLength(2), MaxLength(1000)]
    public required string Message { get; init; }

    /// <summary>Response language code: en or vi. Defaults to English.</summary>
    [RegularExpression("^(en|vi)$")]
    public string Language { get; init; } = "en";

    [RegularExpression("^(Men|Women|Unisex)$")]
    public string? Gender { get; init; }

    [MaxLength(120)]
    public string? Category { get; init; }

    [MaxLength(6)]
    public IReadOnlyList<ChatMessageItem>? History { get; init; }
}

/// <summary>Optional action chip for the Flutter client.</summary>
public sealed record ChatAssistantSuggestion(
    string Type,
    Guid ProductVariantId,
    string ProductName,
    string Size,
    string Label);

/// <summary>Answer from the BigFit catalogue assistant.</summary>
public sealed record ChatAssistantResponse(
    string Answer,
    IReadOnlyList<ChatAssistantSuggestion> Suggestions);
