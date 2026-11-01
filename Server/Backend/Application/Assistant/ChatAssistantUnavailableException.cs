namespace BigFit.Application.Assistant;

public sealed class ChatAssistantUnavailableException(string message, string title)
    : Exception(message)
{
    public string Title { get; } = title;
}
