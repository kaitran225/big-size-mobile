using System.ComponentModel.DataAnnotations;

namespace BigFit.Application.Assistant;

/// <summary>Single turn message in chat history.</summary>
public sealed record ChatMessageDto
{
    [Required]
    public required string Role { get; init; }

    [Required]
    public required string Content { get; init; }
}

/// <summary>Question for the BigFit catalogue assistant.</summary>
public sealed record ChatAssistantRequest
{
    [Required, MinLength(2), MaxLength(1000)]
    public required string Message { get; init; }

    [RegularExpression("^(Men|Women|Unisex)$")]
    public string? Gender { get; init; }

    [MaxLength(120)]
    public string? Category { get; init; }

    public IReadOnlyList<ChatMessageDto>? History { get; init; }
}

/// <summary>Answer from the BigFit catalogue assistant.</summary>
public sealed record ChatAssistantResponse(string Answer);
