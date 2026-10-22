using BigFit.Application.Abstractions;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class ApiDocumentationEndpoints
{
    public static WebApplication MapApiDocumentation(this WebApplication app)
    {
        app.MapGet("/", () => TypedResults.Redirect("/swagger"))
            .ExcludeFromDescription();

        app.MapGet("/swagger", GetSwaggerUi)
            .ExcludeFromDescription();

        app.MapGet("/swagger/index.html", GetSwaggerUi)
            .ExcludeFromDescription();

        return app;
    }

    private static ContentHttpResult GetSwaggerUi() =>
        TypedResults.Content(ApiMessages.SwaggerUiDocument, "text/html; charset=utf-8");
}
