using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class ApiDocumentationEndpoints
{
    private const string SwaggerUiHtml = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>BigFit API documentation</title>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">
          <style>
            html { box-sizing: border-box; overflow-y: scroll; }
            *, *::before, *::after { box-sizing: inherit; }
            body { margin: 0; background: #faf9f6; }
            .swagger-ui .topbar { background: #174c3c; }
          </style>
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
          <script>
            window.onload = () => SwaggerUIBundle({
              url: "/openapi/v1.json",
              dom_id: "#swagger-ui",
              deepLinking: true,
              displayRequestDuration: true,
              presets: [SwaggerUIBundle.presets.apis],
              layout: "BaseLayout"
            });
          </script>
        </body>
        </html>
        """;

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
        TypedResults.Content(SwaggerUiHtml, "text/html; charset=utf-8");
}
