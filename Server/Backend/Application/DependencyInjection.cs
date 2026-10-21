using BigFit.Application.Catalog;
using Microsoft.Extensions.DependencyInjection;

namespace BigFit.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<ICatalogService, CatalogService>();
        return services;
    }
}
