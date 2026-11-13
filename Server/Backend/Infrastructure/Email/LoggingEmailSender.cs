using BigFit.Application.Abstractions;

namespace BigFit.Infrastructure.Email;

internal sealed class LoggingEmailSender(ILogger<LoggingEmailSender> logger) : IEmailSender
{
    public Task SendAsync(
        string recipient,
        string subject,
        string plainTextBody,
        CancellationToken cancellationToken)
    {
        logger.LogWarning(
            "EMAIL (logging mode) To={Recipient} Subject={Subject} Body={Body}",
            recipient,
            subject,
            plainTextBody);
        return Task.CompletedTask;
    }
}
