namespace BigFit.Application.Assistant;

using BigFit.Application.Abstractions;

/// <summary>
/// References strings centralized in <see cref="ApiMessages"/> for the AI assistant module.
/// </summary>
public static class AssistantMessages
{
    // ---------------------------------------------------------------------
    // Provider prompt & fallbacks
    // ---------------------------------------------------------------------

    public const string SystemPrompt = ApiMessages.AssistantSystemPrompt;
    public const string OutOfScopeFallback = ApiMessages.AssistantOutOfScopeFallback;
    public const string SizeGuideFallback = ApiMessages.AssistantSizeGuideFallback;
    public const string PoliciesFallback = ApiMessages.AssistantPoliciesFallback;
    public const string GeneralFallback = ApiMessages.AssistantGeneralFallback;

    // ---------------------------------------------------------------------
    // Failure messages
    // ---------------------------------------------------------------------

    public const string UnavailableTitle = ApiMessages.AssistantUnavailableTitle;
    public const string NotConfigured = ApiMessages.AssistantNotConfigured;
    public const string ProviderRequestFailed = ApiMessages.AssistantProviderRequestFailed;
    public const string ProviderEmptyResponse = ApiMessages.AssistantProviderEmptyResponse;
    public const string ProviderUnavailable = ApiMessages.AssistantProviderUnavailable;
    public const string ProviderTimedOut = ApiMessages.AssistantProviderTimedOut;
    public const string ProviderInvalidResponse = ApiMessages.AssistantProviderInvalidResponse;

    // ---------------------------------------------------------------------
    // Logging
    // ---------------------------------------------------------------------

    public const string ProviderErrorStatusLog = ApiMessages.AssistantProviderErrorStatusLog;
    public const string ProviderUnreachableLog = ApiMessages.AssistantProviderUnreachableLog;
    public const string ProviderTimeoutLog = ApiMessages.AssistantProviderTimeoutLog;

    // ---------------------------------------------------------------------
    // OpenAPI text
    // ---------------------------------------------------------------------

    public const string Tag = ApiMessages.TagAssistant;
    public const string Summary = ApiMessages.SummaryAskAssistant;
    public const string Description = ApiMessages.DescriptionAskAssistant;
}
