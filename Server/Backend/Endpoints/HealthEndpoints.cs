using BigFit.Application.Abstractions;
using Microsoft.AspNetCore.Http.HttpResults;
using Npgsql;

namespace BigFit.Api.Endpoints;

/// <summary>Reports the result of a database connectivity check.</summary>
public sealed record DatabaseHealthResponse(string Status);

public static class HealthEndpoints
{
    public static IEndpointRouteBuilder MapHealthEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/api/database/health", async Task<Results<Ok<DatabaseHealthResponse>, ProblemHttpResult>> (
            IDatabaseHealthCheck healthCheck,
            ILogger<DatabaseHealthResponse> logger,
            CancellationToken cancellationToken) =>
        {
            try
            {
                await healthCheck.CheckAsync(cancellationToken);
                return TypedResults.Ok(new DatabaseHealthResponse(ApiMessages.DatabaseHealthy));
            }
            catch (NpgsqlException exception)
            {
                logger.LogWarning(exception, ApiMessages.DatabaseHealthCheckFailedLog);
                return TypedResults.Problem(
                    statusCode: StatusCodes.Status503ServiceUnavailable,
                    title: ApiMessages.DatabaseUnavailableTitle,
                    detail: ApiMessages.DatabaseUnavailableDetail);
            }
        })
        .WithName("GetDatabaseHealth")
        .WithSummary(ApiMessages.SummaryGetDatabaseHealth)
        .ProducesProblem(StatusCodes.Status503ServiceUnavailable);

        return endpoints;
    }
}
