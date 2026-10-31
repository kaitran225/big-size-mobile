using BigFit.Api.Endpoints;
using BigFit.Api.Middleware;
using BigFit.Api.OpenApi;
using BigFit.Application;
using BigFit.Application.Authentication;
using BigFit.Infrastructure;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Persistence;
using BigFit.Api.Realtime;
using BigFit.Application.Abstractions;
using BigFit.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.HttpOverrides;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
var renderPort = Environment.GetEnvironmentVariable("PORT");
if (int.TryParse(renderPort, out var port) && port is > 0 and <= 65535)
{
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
}

builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer<BearerSecuritySchemeTransformer>();
    options.AddOperationTransformer<BearerSecurityRequirementTransformer>();
});
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

// The public host terminates TLS and forwards to the container over HTTP.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

if (!builder.Environment.IsDevelopment())
{
    builder.Services.Configure<HttpsRedirectionOptions>(options => options.HttpsPort = 443);
}

var app = builder.Build();

app.UseForwardedHeaders();
app.UseHttpsRedirection();
app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors("FlutterClient");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapOpenApi();
app.MapApiDocumentation();

await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BigFitDbContext>();
    if (db.Database.IsRelational())
    {
        if (app.Configuration.GetValue<bool>("Database:ApplyMigrationsOnStartup"))
        {
            await db.Database.MigrateAsync(app.Lifetime.ApplicationStopping);
        }
    }
    else
    {
        await db.Database.EnsureCreatedAsync(app.Lifetime.ApplicationStopping);
    }

    await scope.ServiceProvider.GetRequiredService<DatabaseInitializer>()
        .InitializeAsync(app.Lifetime.ApplicationStopping);

    await SeedLocalProductsAsync(db);
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

static async Task SeedLocalProductsAsync(BigFitDbContext db)
{
    if (await db.Products.AnyAsync()) return;

    var menShirts = await db.Categories.FirstOrDefaultAsync(c => c.Name == "Shirts" && c.Gender == "Men")
                    ?? await db.Categories.FirstOrDefaultAsync(c => c.Gender == "Men");
    if (menShirts == null) return;

    var menCasual = await db.Categories.FirstOrDefaultAsync(c => c.Name == "Casualwear" && c.Gender == "Men") ?? menShirts;
    var menBottoms = await db.Categories.FirstOrDefaultAsync(c => c.Name == "Bottoms" && c.Gender == "Men") ?? menShirts;
    var womenDresses = await db.Categories.FirstOrDefaultAsync(c => c.Name.Contains("Dresses") && c.Gender == "Women")
                       ?? await db.Categories.FirstOrDefaultAsync(c => c.Gender == "Women") ?? menShirts;

    var p1 = new Product
    {
        Name = "Classic BigFit Shirt",
        Description = "Áo sơ mi nam công sở form rộng, chất liệu cotton thoáng mát cao cấp.",
        Price = 399000,
        SalePrice = 349000,
        CurrencyCode = "VND",
        CategoryId = menShirts.Id,
        IsActive = true,
        Variants = [
            new ProductVariant { Sku = "BFS-SHIRT-2XL-BLK", Size = "2XL", Color = "Black", StockQuantity = 15 },
            new ProductVariant { Sku = "BFS-SHIRT-3XL-BLK", Size = "3XL", Color = "Black", StockQuantity = 20 },
            new ProductVariant { Sku = "BFS-SHIRT-4XL-BLK", Size = "4XL", Color = "Black", StockQuantity = 10 },
            new ProductVariant { Sku = "BFS-SHIRT-3XL-WHT", Size = "3XL", Color = "White", StockQuantity = 12 }
        ]
    };

    var p2 = new Product
    {
        Name = "BigFit Polo Active",
        Description = "Áo Polo nam thun cá sấu co giãn 4 chiều, thiết kế giấu bụng tôn dáng.",
        Price = 299000,
        SalePrice = 259000,
        CurrencyCode = "VND",
        CategoryId = menCasual.Id,
        IsActive = true,
        Variants = [
            new ProductVariant { Sku = "BFS-POLO-XL-GRY", Size = "XL", Color = "Gray", StockQuantity = 18 },
            new ProductVariant { Sku = "BFS-POLO-2XL-GRY", Size = "2XL", Color = "Gray", StockQuantity = 25 },
            new ProductVariant { Sku = "BFS-POLO-3XL-BLK", Size = "3XL", Color = "Black", StockQuantity = 15 }
        ]
    };

    var p3 = new Product
    {
        Name = "BigFit Relaxed Chino Pants",
        Description = "Quần dài Chino Big Size cạp chun co giãn cực kỳ thoải mái khi vận động.",
        Price = 450000,
        CurrencyCode = "VND",
        CategoryId = menBottoms.Id,
        IsActive = true,
        Variants = [
            new ProductVariant { Sku = "BFS-CHINO-2XL-KHK", Size = "2XL", Color = "Khaki", StockQuantity = 10 },
            new ProductVariant { Sku = "BFS-CHINO-3XL-BLK", Size = "3XL", Color = "Black", StockQuantity = 15 },
            new ProductVariant { Sku = "BFS-CHINO-4XL-BLK", Size = "4XL", Color = "Black", StockQuantity = 8 }
        ]
    };

    var p4 = new Product
    {
        Name = "BigFit Elegant Linen Dress",
        Description = "Đầm suông Linen nữ cao cấp dáng suông rộng thanh lịch giấu dáng khuyết điểm.",
        Price = 520000,
        SalePrice = 469000,
        CurrencyCode = "VND",
        CategoryId = womenDresses.Id,
        IsActive = true,
        Variants = [
            new ProductVariant { Sku = "BFS-DRESS-XL-BGE", Size = "XL", Color = "Beige", StockQuantity = 12 },
            new ProductVariant { Sku = "BFS-DRESS-2XL-BGE", Size = "2XL", Color = "Beige", StockQuantity = 16 },
            new ProductVariant { Sku = "BFS-DRESS-3XL-BLU", Size = "3XL", Color = "Pastel Blue", StockQuantity = 10 }
        ]
    };

    db.Products.AddRange(p1, p2, p3, p4);
    await db.SaveChangesAsync();
}
