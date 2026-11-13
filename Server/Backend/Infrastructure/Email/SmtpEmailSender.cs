using System.Net;
using System.Net.Mail;
using BigFit.Application.Abstractions;

namespace BigFit.Infrastructure.Email;

internal sealed class SmtpEmailSender(IConfiguration configuration) : IEmailSender
{
    public async Task SendAsync(
        string recipient,
        string subject,
        string plainTextBody,
        CancellationToken cancellationToken)
    {
        var host = configuration["Email:Smtp:Host"];
        var portText = configuration["Email:Smtp:Port"];
        if (string.IsNullOrWhiteSpace(host) || !int.TryParse(portText, out var port))
        {
            throw new InvalidOperationException("Email:Smtp:Host and Email:Smtp:Port must be configured.");
        }

        var fromAddress = configuration["Email:Smtp:FromAddress"]
            ?? throw new InvalidOperationException("Email:Smtp:FromAddress is required.");
        var fromName = configuration["Email:Smtp:FromName"] ?? "BigFit";
        var username = configuration["Email:Smtp:Username"];
        var password = configuration["Email:Smtp:Password"];
        var enableSsl = configuration.GetValue("Email:Smtp:EnableSsl", true);

        using var message = new MailMessage
        {
            From = new MailAddress(fromAddress, fromName),
            Subject = subject,
            Body = plainTextBody,
            IsBodyHtml = false
        };
        message.To.Add(recipient);

        using var client = new SmtpClient(host, port)
        {
            EnableSsl = enableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network
        };

        if (!string.IsNullOrWhiteSpace(username))
        {
            client.Credentials = new NetworkCredential(username, password);
        }

        cancellationToken.ThrowIfCancellationRequested();
        await client.SendMailAsync(message, cancellationToken);
    }
}
