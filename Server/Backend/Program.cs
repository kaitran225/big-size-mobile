using BigFit.Api.Endpoints;
using BigFit.Api.Middleware;
using BigFit.Application;
using BigFit.Application.Authentication;
using BigFit.Infrastructure;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Persistence;
using BigFit.Api.Realtime;
using BigFit.Application.Abstractions;
using Microsoft.EntityFrameworkCore;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
var renderPort = Environment.GetEnvironmentVariable("PORT");
if (int.TryParse(renderPort, out var port) && port is > 0 and <= 65535)
{
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
}

builder.Services.AddOpenApi();
builder.Services.AddValidation();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddApplication();
builder.Services.AddSignalR();
builder.Services.AddSingleton<INotificationEventPublisher, SignalRNotificationEventPublisher>();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddAuthorizationBuilder()
    .AddPolicy(ApplicationRoles.Admin, policy => policy.RequireRole(ApplicationRoles.Admin))
    .AddPolicy(ApplicationRoles.CatalogManagement, policy => policy
        .RequireRole(ApplicationRoles.Admin, ApplicationRoles.StoreStaff));
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("authentication", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            }));
    options.AddPolicy("assistant", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            }));
});
builder.Services.AddCors(options => options.AddPolicy("FlutterClient", policy =>
    policy.AllowAnyOrigin()
        .AllowAnyHeader()
        .AllowAnyMethod()));

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors("FlutterClient");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapOpenApi();

app.UseHttpsRedirection();
await using (var scope = app.Services.CreateAsyncScope())
{
    if (app.Configuration.GetValue<bool>("Database:ApplyMigrationsOnStartup"))
    {
        await scope.ServiceProvider.GetRequiredService<BigFitDbContext>()
            .Database.MigrateAsync(app.Lifetime.ApplicationStopping);
    }

    await scope.ServiceProvider.GetRequiredService<DatabaseInitializer>()
        .InitializeAsync(app.Lifetime.ApplicationStopping);
}

app.MapHealthEndpoints();
app.MapAuthenticationEndpoints();
app.MapCategoryEndpoints();
app.MapProductEndpoints();
app.MapNotificationEndpoints();
app.MapShoppingEndpoints();
app.MapAddressEndpoints();
app.MapChatAssistantEndpoints();
app.MapHub<NotificationHub>("/hubs/notifications").RequireAuthorization();

app.Run();
