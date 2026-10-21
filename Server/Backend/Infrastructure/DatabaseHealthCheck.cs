using BigFit.Application.Abstractions;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Persistence;

internal sealed class DatabaseHealthCheck(BigFitDbContext dbContext) : IDatabaseHealthCheck
{
    public async Task CheckAsync(CancellationToken cancellationToken) =>
        await dbContext.Database.ExecuteSqlRawAsync("SELECT 1", cancellationToken);
}
