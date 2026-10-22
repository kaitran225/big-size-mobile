# BigFit Backend

The ASP.NET Core API is a single project at `Backend\Backend.csproj`. Clean
Architecture boundaries remain grouped in the project:

- `Endpoints`, `Middleware`, and `Program.cs` — HTTP, validation, auth policies,
  rate limiting, CORS, OpenAPI, and error handling.
- `Application` — catalogue/auth use cases, contracts, and repository ports.
- `Domain` — product, category, and variant entities.
- `Infrastructure` — EF Core/PostgreSQL, ASP.NET Identity, and JWT issuance.

### Deploy to Render

1. Push this repository to GitHub and create a **Blueprint** in Render using
   the repository's `render.yaml`.
2. Set the secret `ConnectionStrings__Default` to the PostgreSQL URI. For the
   existing Aiven database, use its public connection URI and retain
   `sslmode=require`; ensure the database allows connections from Render.
3. Set `Auth__Jwt__SigningKey` to a fresh, random value of at least 32 bytes.
   Do not reuse or commit a signing key from a local `.env`.
4. Optionally set `Auth__BootstrapAdmin__Email` and
   `Auth__BootstrapAdmin__Password` before the first deploy to provision the
   initial Admin. The password must satisfy the Identity policy.
5. If the AI helper is needed, set `Ai__OpenAiCompatible__BaseUrl`,
   `Ai__OpenAiCompatible__ApiKey`, and `Ai__OpenAiCompatible__Model` as
   Render environment variables. Never put the provider key in Flutter.
6. Deploy and confirm Render's `/api/health/database` health check succeeds.
   Swagger UI is available at `/swagger` (and `/` redirects there). The raw
   OpenAPI document is available at `/openapi/v1.json`.