using BigFit.Application.Abstractions;
using BigFit.Application.Assistant;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class ChatAssistantEndpoints
{
    public static IEndpointRouteBuilder MapChatAssistantEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost("/api/assistant/chat", async Task<Ok<ChatAssistantResponse>> (
            ChatAssistantRequest request,
            IChatAssistantService assistant,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await assistant.AskAsync(request, cancellationToken)))
        .WithTags(AssistantMessages.Tag)
        .WithName("AskBigFitAssistant")
        .WithSummary(AssistantMessages.Summary)
        .WithDescription(AssistantMessages.Description)
        .RequireAuthorization()
        .RequireRateLimiting("assistant");

        return endpoints;
    }
}
