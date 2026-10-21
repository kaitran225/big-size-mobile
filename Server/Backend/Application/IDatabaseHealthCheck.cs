namespace BigFit.Application.Abstractions;

public interface IDatabaseHealthCheck
{
    Task CheckAsync(CancellationToken cancellationToken);
}
