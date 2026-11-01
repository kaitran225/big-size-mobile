using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Assistant;

/// <summary>Single turn message in chat history.</summary>
public sealed record ChatMessageItem(
    [Required] string Role,
    [Required] string Content);

/// <summary>Question for the BigFit catalogue assistant.</summary>
public sealed record ChatAssistantRequest
{
    [Required, MinLength(2), MaxLength(1000)]
    public required string Message { get; init; }

    [RegularExpression("^(Men|Women|Unisex)$")]
    public string? Gender { get; init; }

    [MaxLength(120)]
    public string? Category { get; init; }

    public IReadOnlyList<ChatMessageItem>? History { get; init; }
}

/// <summary>Answer from the BigFit catalogue assistant.</summary>
public sealed record ChatAssistantResponse(string Answer);
