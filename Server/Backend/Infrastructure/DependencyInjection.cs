using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Assistant;
using BigFit.Infrastructure.Notifications;
using BigFit.Infrastructure.Shopping;
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
        var configuredConnection = configuration.GetConnectionString("Default");
        if (string.IsNullOrWhiteSpace(configuredConnection))
        {
            throw new InvalidOperationException(
                "Database connection is not configured. Set ConnectionStrings:Default using .NET user-secrets or an environment variable.");
        }

        var signingKey = configuration["Auth:Jwt:SigningKey"];
        var issuer = configuration["Auth:Jwt:Issuer"];
        var audience = configuration["Auth:Jwt:Audience"];
        if (string.IsNullOrWhiteSpace(signingKey) || Encoding.UTF8.GetByteCount(signingKey) < 32)
        {
            throw new InvalidOperationException(
                "Auth:Jwt:SigningKey must be configured as a secret of at least 32 UTF-8 bytes.");
        }

        if (string.IsNullOrWhiteSpace(issuer) || string.IsNullOrWhiteSpace(audience))
        {
            throw new InvalidOperationException("Auth:Jwt:Issuer and Auth:Jwt:Audience must be configured.");
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
        services.AddScoped<ICatalogRepository, CatalogRepository>();
        services.AddScoped<IDatabaseHealthCheck, DatabaseHealthCheck>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IShoppingService, ShoppingService>();
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
                "The PostgreSQL URL must include a username, password, and database name.");
        }

        var sslMode = uri.Query.TrimStart('?')
            .Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(parameter => parameter.Split('=', 2))
            .Where(parts => Uri.UnescapeDataString(parts[0]).Equals("sslmode", StringComparison.OrdinalIgnoreCase))
            .Select(parts => parts.Length == 2 ? Uri.UnescapeDataString(parts[1]) : string.Empty)
            .FirstOrDefault();

        if (!string.Equals(sslMode, "require", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("The PostgreSQL URL must use sslmode=require.");
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
