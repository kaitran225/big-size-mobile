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
        endpoints.MapGet("/api/health/database", async Task<Results<Ok<DatabaseHealthResponse>, ProblemHttpResult>> (
            IDatabaseHealthCheck healthCheck,
            ILogger<DatabaseHealthResponse> logger,
            CancellationToken cancellationToken) =>
        {
            try
            {
                await healthCheck.CheckAsync(cancellationToken);
                return TypedResults.Ok(new DatabaseHealthResponse("healthy"));
            }
            catch (NpgsqlException exception)
            {
                logger.LogWarning(exception, "PostgreSQL health check failed.");
                return TypedResults.Problem(
                    statusCode: StatusCodes.Status503ServiceUnavailable,
                    title: "Database unavailable",
                    detail: "The database health check could not connect to PostgreSQL.");
            }
        })
        .WithName("GetDatabaseHealth")
        .WithSummary("Check PostgreSQL connectivity")
        .ProducesProblem(StatusCodes.Status503ServiceUnavailable);

        return endpoints;
    }
}
