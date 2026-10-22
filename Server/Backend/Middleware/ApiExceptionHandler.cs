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
                ApiMessages.InvalidRequestTitle,
                ApiMessages.InvalidRequestBodyDetail),
            DataConflictException => (
                StatusCodes.Status409Conflict,
                ApiMessages.DataConflictTitle,
                exception.Message),
            AuthenticationOperationException authException => (
                authException.StatusCode,
                authException.Title,
                authException.Message),
            ChatAssistantUnavailableException assistantException => (
                StatusCodes.Status503ServiceUnavailable,
                AssistantMessages.UnavailableTitle,
                assistantException.Message),
            ArgumentException => (
                StatusCodes.Status400BadRequest,
                ApiMessages.InvalidRequestTitle,
                exception.Message),
            _ => (
                StatusCodes.Status500InternalServerError,
                ApiMessages.UnexpectedErrorTitle,
                ApiMessages.UnexpectedErrorDetail)
        };

        logger.LogError(exception, ApiMessages.ApiRequestFailedLog, status);
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
