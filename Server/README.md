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

### SePay sandbox

Catalog prices stay in EUR. Bank Hub converts the order total to VND with
`Payments:SePay:EurToVndRate` (default 27000). Cash on delivery does not call
SePay. Bank transfer and card stay pending until a sandbox credit IPN arrives.

The public origin is `https://big-fit-pgm-store.onrender.com`. SePay cannot
call `localhost`. On the Bank Hub sandbox page, set Notify URL to
`https://big-fit-pgm-store.onrender.com/api/payments/sepay/ipn` and Notify API
Key to the same value as `IpnSecretKey`.

Set the sandbox secrets without committing them. On Render, set
`Payments__SePay__ClientId`, `Payments__SePay__ClientSecret`,
`Payments__SePay__IpnSecretKey`, and `Payments__SePay__BankAccountXid`.
`Payments__SePay__PublicBaseUrl` and `Payments__SePay__ApiBaseUrl` are already
in `render.yaml`. Locally, from `Server`:

```powershell
dotnet user-secrets set "Payments:SePay:ClientId" "YOUR_BANK_HUB_CLIENT_ID" --project Backend
dotnet user-secrets set "Payments:SePay:ClientSecret" "YOUR_BANK_HUB_CLIENT_SECRET" --project Backend
dotnet user-secrets set "Payments:SePay:IpnSecretKey" "YOUR_NOTIFY_API_KEY" --project Backend
dotnet user-secrets set "Payments:SePay:PublicBaseUrl" "https://big-fit-pgm-store.onrender.com" --project Backend
dotnet user-secrets set "Payments:SePay:BankAccountXid" "YOUR_LINKED_ACCOUNT_XID" --project Backend
```

The app shows the VND amount, bank code, and transfer content, then a demo
button creates a sandbox credit. SePay posts that credit to the IPN. A repeated
`transaction_id` does not overwrite a payment that already succeeded.
