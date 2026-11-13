using System.Security.Claims;
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
            HttpContext httpContext,
            CancellationToken cancellationToken) =>
        {
            Guid? userId = null;
            var subject = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? httpContext.User.FindFirstValue("sub");
            if (Guid.TryParse(subject, out var parsed))
            {
                userId = parsed;
            }

            return TypedResults.Ok(await assistant.AskAsync(request, userId, cancellationToken));
        })
        .WithTags(AssistantMessages.Tag)
        .WithName("AskBigFitAssistant")
        .WithSummary(AssistantMessages.Summary)
        .WithDescription(AssistantMessages.Description)
        .RequireAuthorization()
        .RequireRateLimiting("assistant");

        return endpoints;
    }
}
