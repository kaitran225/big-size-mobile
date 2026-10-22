using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using BigFit.Application.Assistant;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace BigFit.Api.Middleware;

internal sealed class ApiExceptionHandler(
    ILogger<ApiExceptionHandler> logger,
    IProblemDetailsService problemDetailsService) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (status, title, detail) = exception switch
        {
            BadHttpRequestException => (
                StatusCodes.Status400BadRequest,
                "Invalid request",
                "The request body is missing or contains invalid JSON."),
            DataConflictException => (
                StatusCodes.Status409Conflict,
                "Data conflict",
                exception.Message),
            AuthenticationOperationException authException => (
                authException.StatusCode,
                authException.Title,
                authException.Message),
            ChatAssistantUnavailableException assistantException => (
                StatusCodes.Status503ServiceUnavailable,
                "AI assistant unavailable",
                assistantException.Message),
            ArgumentException => (
                StatusCodes.Status400BadRequest,
                "Invalid request",
                exception.Message),
            _ => (
                StatusCodes.Status500InternalServerError,
                "An unexpected error occurred",
                "The server could not complete the request.")
        };

        logger.LogError(exception, "API request failed with status {StatusCode}.", status);
        httpContext.Response.StatusCode = status;
        await problemDetailsService.WriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            ProblemDetails = new ProblemDetails
            {
                Status = status,
                Title = title,
                Detail = detail,
                Instance = httpContext.Request.Path
            },
            Exception = exception
        });
        return true;
    }
}
