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
        .WithTags("AI assistant")
        .WithName("AskBigFitAssistant")
        .WithSummary("Ask a concise catalogue-grounded question")
        .WithDescription("The model receives compact category aggregates and at most eight relevant product summaries.")
        .RequireAuthorization()
        .RequireRateLimiting("assistant");

        return endpoints;
    }
}
