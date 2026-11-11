using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Assistant;
using BigFit.Infrastructure.Notifications;
using BigFit.Infrastructure.Shopping;
using BigFit.Infrastructure.Payments;
using BigFit.Infrastructure.Addresses;
using BigFit.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using System.Text;

namespace BigFit.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var rawConnection = configuration.GetConnectionString("Default");
        var configuredConnection = rawConnection == null
            ? "Host=localhost;Port=5432;Database=bigfit_local;Username=postgres"
            : rawConnection;

        var rawKey = configuration["Auth:Jwt:SigningKey"];
        var signingKey = rawKey == null
            ? "BigFit.LocalDevelopment.SigningKey.Only.NotForProduction.2026"
            : rawKey;

        var rawIssuer = configuration["Auth:Jwt:Issuer"];
        var issuer = rawIssuer == null
            ? "BigFit.Backend"
            : rawIssuer;

        var rawAudience = configuration["Auth:Jwt:Audience"];
        var audience = rawAudience == null
            ? "BigFit.Mobile"
            : rawAudience;

        if (string.IsNullOrWhiteSpace(configuredConnection))
        {
            throw new InvalidOperationException(
                ApiMessages.DatabaseConnectionNotConfigured);
        }

        if (string.IsNullOrWhiteSpace(signingKey) || Encoding.UTF8.GetByteCount(signingKey) < 32)
        {
            throw new InvalidOperationException(
                ApiMessages.JwtSigningKeyNotConfigured);
        }

        if (string.IsNullOrWhiteSpace(issuer) || string.IsNullOrWhiteSpace(audience))
        {
            throw new InvalidOperationException(ApiMessages.JwtIssuerAudienceNotConfigured);
        }

        services.AddDbContext<BigFitDbContext>(options =>
            options.UseNpgsql(ToNpgsqlConnectionString(configuredConnection)));
        services.AddIdentityCore<ApplicationUser>(options =>
            {
                options.User.RequireUniqueEmail = true;
                options.Password.RequiredLength = 12;
                options.Password.RequireDigit = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = true;
                options.Lockout.MaxFailedAccessAttempts = 5;
                options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
                options.Lockout.AllowedForNewUsers = true;
            })
            .AddRoles<IdentityRole<Guid>>()
            .AddEntityFrameworkStores<BigFitDbContext>()
            .AddSignInManager();
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = issuer,
                    ValidateAudience = true,
                    ValidAudience = audience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromSeconds(30),
                    NameClaimType = System.Security.Claims.ClaimTypes.Name,
                    RoleClaimType = System.Security.Claims.ClaimTypes.Role
                };
                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        var accessToken = context.Request.Query["access_token"];
                        if (!string.IsNullOrEmpty(accessToken) &&
                            context.Request.Path.StartsWithSegments("/hubs/notifications"))
                        {
                            context.Token = accessToken;
                        }

                        return Task.CompletedTask;
                    }
                };
            });
        services.AddScoped<IAuthenticationService, AuthenticationService>();
        services.AddSingleton<JwtTokenIssuer>();
        services.AddScoped<DatabaseInitializer>();
        services.AddScoped<DevelopmentCatalogSeeder>();
        services.AddScoped<ICatalogRepository, CatalogRepository>();
        services.AddScoped<IDatabaseHealthCheck, DatabaseHealthCheck>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IShoppingService, ShoppingService>();
        services.AddScoped<IPaymentService, SePayPaymentService>();
        services.AddHttpClient(nameof(SePayPaymentService), client =>
            client.Timeout = TimeSpan.FromSeconds(20));
        services.AddScoped<IAddressService, AddressService>();
        services.AddHttpClient<IChatAssistantService, ChatAssistantService>(client =>
            client.Timeout = TimeSpan.FromSeconds(25));
        return services;
    }

    private static string ToNpgsqlConnectionString(string connectionString)
    {
        if (!Uri.TryCreate(connectionString, UriKind.Absolute, out var uri) ||
            (uri.Scheme != "postgres" && uri.Scheme != "postgresql"))
        {
            return connectionString;
        }

        var credentials = uri.UserInfo.Split(':', 2);
        var database = Uri.UnescapeDataString(uri.AbsolutePath.Trim('/'));
        if (credentials.Length != 2 || string.IsNullOrWhiteSpace(database))
        {
            throw new InvalidOperationException(
                ApiMessages.PostgresUrlMissingCredentials);
        }

        var sslMode = uri.Query.TrimStart('?')
            .Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(parameter => parameter.Split('=', 2))
            .Where(parts => Uri.UnescapeDataString(parts[0]).Equals("sslmode", StringComparison.OrdinalIgnoreCase))
            .Select(parts => parts.Length == 2 ? Uri.UnescapeDataString(parts[1]) : string.Empty)
            .FirstOrDefault();

        if (!string.Equals(sslMode, "require", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(ApiMessages.PostgresUrlRequiresSsl);
        }

        return new NpgsqlConnectionStringBuilder
        {
            Host = uri.Host,
            Port = uri.Port,
            Database = database,
            Username = Uri.UnescapeDataString(credentials[0]),
            Password = Uri.UnescapeDataString(credentials[1]),
            SslMode = SslMode.Require
        }.ConnectionString;
    }
}
