namespace BigFit.Application.Assistant;

/// <summary>
/// Every piece of text owned by the AI assistant: the system prompt sent to
/// the provider, the messages returned to the client when the assistant
/// cannot answer, and the OpenAPI documentation for the endpoint.
/// </summary>
public static class AssistantMessages
{
    // ---------------------------------------------------------------------
    // Provider prompt
    // ---------------------------------------------------------------------

    /// <summary>
    /// System prompt that keeps the assistant grounded in the catalogue data
    /// supplied with each question.
    /// </summary>
    public const string SystemPrompt =
        "You are BigFit's concise clothing shopping assistant. Answer only from the supplied BigFit catalogue data. " +
        "Never invent prices, stock, sizes, policies, or products. Explain when requested information is absent. " +
        "Use the product's currentPrice for today's price and mention salePrice only when isOnSale is true. " +
        "Keep answers brief and recommend checking fit because sizes vary by garment.";

    // ---------------------------------------------------------------------
    // Failure messages
    // ---------------------------------------------------------------------

    public const string UnavailableTitle = "AI assistant unavailable";
    public const string NotConfigured =
        "AI assistant is not configured. Set the AI provider endpoint, API key, and model.";
    public const string ProviderRequestFailed =
        "The AI provider could not complete the request.";
    public const string ProviderEmptyResponse =
        "The AI provider returned an empty response.";
    public const string ProviderUnavailable =
        "The AI provider is temporarily unavailable.";
    public const string ProviderTimedOut =
        "The AI provider request timed out.";
    public const string ProviderInvalidResponse =
        "The AI provider returned an invalid response.";

    // ---------------------------------------------------------------------
    // Logging
    // ---------------------------------------------------------------------

    public const string ProviderErrorStatusLog =
        "Configured AI provider returned HTTP {StatusCode}.";
    public const string ProviderUnreachableLog =
        "Could not reach the configured AI provider.";
    public const string ProviderTimeoutLog =
        "The configured AI provider timed out.";

    // ---------------------------------------------------------------------
    // OpenAPI text
    // ---------------------------------------------------------------------

    public const string Tag = "AI assistant";
    public const string Summary = "Ask a concise catalogue-grounded question";
    public const string Description =
        "The model receives compact category aggregates and at most eight relevant product summaries.";
}
