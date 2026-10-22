# BigFit Backend

The ASP.NET Core API is a single project at `Backend\Backend.csproj`. Clean
Architecture boundaries remain grouped in the project:

- `Endpoints`, `Middleware`, and `Program.cs` — HTTP, validation, auth policies,
  rate limiting, CORS, OpenAPI, and error handling.
- `Application` — catalogue/auth use cases, contracts, and repository ports.
- `Domain` — product, category, and variant entities.
- `Infrastructure` — EF Core/PostgreSQL, ASP.NET Identity, and JWT issuance.

## Database and secrets

The backend connects to PostgreSQL using `ConnectionStrings:Default`. Store
the URI in .NET user-secrets locally, or in your hosting provider's secret
manager using `ConnectionStrings__Default`.

```powershell
dotnet user-secrets set "ConnectionStrings:Default" "<postgresql URI>" --project Backend\Backend.csproj
```

JWT signing keys must be secret and at least 32 UTF-8 bytes. Do not commit
them or put them in appsettings files.

```powershell
dotnet user-secrets set "Auth:Jwt:SigningKey" "<random secret of at least 32 bytes>" --project Backend\Backend.csproj
```

The issuer and audience are configured in appsettings. Access tokens expire
after 30 minutes by default.

## Apply the schema and run the API

The migrations add gendered catalog categories, product sale pricing, ASP.NET
Identity, and supporting shopping, map-address, payment, email-outbox, email
verification, OTP, review, and notification tables. Applying them does
**not** import product rows from the review CSV.

```powershell
dotnet tool install --global dotnet-ef --version 10.0.4
dotnet ef database update --project Backend\Backend.csproj
dotnet run --project Backend\Backend.csproj
```

The API listens on `http://localhost:5047` in the `http` launch profile.
The Swagger UI is available at `/swagger`; `/` redirects to it. The OpenAPI
document is available at `/openapi/v1.json` in every environment, and PostgreSQL
readiness is checked at `/api/health/database`.

CORS currently allows requests from any origin, with any header and method, to
support development and demos. This is intentionally permissive; restrict the
origins, headers, and methods before deploying the API publicly. Credentials
are not enabled for cross-origin requests.

## Catalogue CSV review (not seeded)

`Backend\Mock\Uniqlo Products.csv` is the supplied source. Regenerate the
review-only file with:

```powershell
.\Backend\Mock\script\prepare-products.ps1
```

This creates `Backend\Mock\BigFitProducts.review.csv`; it does not connect to
or write to the database. The CSV contains only the fields needed for
categories, products, sale prices, currency, variants, images, and stock.
Each row represents a product variant; repeated product names are grouped
into one product during a future import.

The review file normalizes the source into 13 Men/Women clothing categories,
merges small source subcategories into broader categories, excludes Kids,
Baby, accessories, and unsupported source rows, and checks for at least 10
distinct product names in every included gender/category. Sale prices are
kept only when they are positive and below the regular price. Source
availability maps to a mock stock quantity of 8 or 0. Standard source sizes
are normalized to BigFit labels from M through 4XL; colors are split into
their own variant field and duplicate mapped variants are consolidated.

Please review `BigFitProducts.review.csv` before a separate import is planned.
No CSV rows are currently auto-imported or seeded into PostgreSQL.

## Data schema and services

Categories carry `Gender` (`Men`, `Women`, or `Unisex`). Products keep regular
price, optional sale price, current price, and `isOnSale`; product variants
store size, color, SKU, and stock. The database also has customer addresses
with coordinates, carts/items, favorites, orders/items, payment records,
product reviews, per-user notifications, OTP challenges, email verification
tokens, and an email outbox. SMTP credentials belong in a secret manager or
environment configuration; they are deliberately not stored in database rows.

Authenticated shopping endpoints provide cart read/add/update/remove,
favorite list/add/remove, and order creation/history. Order creation snapshots
sale-adjusted prices, validates address ownership and available stock, and
decrements stock in a transaction using optimistic concurrency. Payment
records are schema scaffolding; payment-provider initiation and callbacks are
not enabled yet.

Authenticated `/api/addresses` CRUD stores delivery details and optional
latitude/longitude together; an address can only be changed or removed by its
owner. Map rendering/provider SDK integration remains a Flutter task.

`POST /api/notifications`, `GET /api/notifications`, `PUT
/api/notifications/{id}/read`, and `DELETE /api/notifications/{id}` are scoped
to the authenticated user. Connected clients can receive SignalR events at
`/hubs/notifications` (`notificationCreated`, `notificationRead`, and
`notificationDeleted`). This is a live socket channel; mobile push delivery
still requires a separate FCM/APNs integration.

## Catalogue AI helper

`POST /api/assistant/chat` requires a customer JWT. It sends a short system
instruction, the question, aggregate category counts, and at most eight
matching product summaries (price, sale status, stock, sizes, and colors) to
an OpenAI-compatible `/chat/completions` endpoint. It does not send full
descriptions or persist conversation history, and caps generated answers to
300 tokens by default (configurable, max 1024).

Set provider configuration through user-secrets locally or secret-backed
environment variables in deployment:

```powershell
dotnet user-secrets set "Ai:OpenAiCompatible:BaseUrl" "https://api.openai.com/v1" --project Backend\Backend.csproj
dotnet user-secrets set "Ai:OpenAiCompatible:ApiKey" "<provider API key>" --project Backend\Backend.csproj
dotnet user-secrets set "Ai:OpenAiCompatible:Model" "<model name>" --project Backend\Backend.csproj
```

The provider key is never sent to Flutter. If provider configuration is
missing, the endpoint returns `503 Service Unavailable`.

## Accounts, roles, and JWT

Roles are `Admin`, `StoreStaff`, and `Customer`. Public registration always
creates a Customer; it cannot choose an elevated role. Passwords are hashed
by ASP.NET Identity, require 12 or more characters with mixed character
types, and are locked out for 15 minutes after five failed sign-in attempts.
Authentication endpoints are rate-limited per client IP.

Configure a dedicated bootstrap administrator using secrets before starting
the API:

```powershell
dotnet user-secrets set "Auth:BootstrapAdmin:Email" "admin@example.com" --project Backend\Backend.csproj
dotnet user-secrets set "Auth:BootstrapAdmin:Password" "<strong unique password>" --project Backend\Backend.csproj
```

The API creates this admin only if that email does not already belong to an
account. It will not promote a pre-existing customer. An Admin can create
StoreStaff accounts through `POST /api/admin/staff`. Catalogue write and
inventory endpoints require Admin or StoreStaff JWT authorization; product
and category reads are public.

## Catalogue API

- `GET /api/categories?gender=Women`
- `GET /api/products?gender=Women&categoryId=...&search=...&size=...&color=...`
- `GET /api/products?onSale=true&inStock=true&sortBy=price_asc&page=1&pageSize=24`
- `GET`, `POST`, `PUT`, and `DELETE` for `/api/products`, `/api/categories`,
  and `/api/products/{productId}/variants`
- Product sale pricing uses optional `SalePrice`; it must be positive and
  below `Price`. Responses include `CurrentPrice`, and product browsing
  supports sale/stock filters and bounded pagination.
- Inactive products are hidden from public catalogue reads. Admin/StoreStaff
  can request them with `includeInactive=true`.

The HTTP request collection in `Backend\app.http` demonstrates auth and
catalogue calls.

## Flutter shop app

The consumer app is `Flutter\app`. Its storefront follows common e-commerce
patterns from the existing UI template while using its own BigFit layout.
It loads categories, search/filter/sort, product pages, sale prices, and
variants from the API. Login/customer registration stores the JWT with
`flutter_secure_storage`. The backend also provides authenticated cart,
favorite, address, and order endpoints; payment initiation still needs a
payment-provider integration.

For Android Emulator, the default API URL is `http://10.0.2.2:5047/api`; for
Flutter Web it is `http://localhost:5047/api`. Override with
`--dart-define=API_BASE_URL=https://<your-api-host>/api` when needed. Android
cleartext traffic is enabled only in the debug manifest.

## Docker and Render deployment

The backend Dockerfile is `Backend\Dockerfile`; the repository blueprint is
`..\render.yaml`. The image uses the .NET 10 runtime, runs as a non-root user,
and listens on Render's `PORT` (or port 8080 locally). Product CSV files and
local environment files are excluded from the Docker build context.

### Run locally in Docker

Copy the template and replace the database URL and JWT key with private values:

```powershell
Copy-Item Backend\.env.example Backend\.env
```

`Backend\.env` is ignored by Git. Keep it private; do not commit it. The
connection string should be the PostgreSQL URI with `sslmode=require`. Provide
a random JWT signing key of at least 32 bytes. AI settings are optional.

From the repository root:

```powershell
docker build -f Server\Backend\Dockerfile -t bigfit-backend Server\Backend
docker run --rm --env-file Server\Backend\.env -p 8080:8080 bigfit-backend
```

When `Database__ApplyMigrationsOnStartup=true`, the backend applies pending
EF Core migrations before initializing roles and the optional bootstrap
administrator. This is enabled in the Render blueprint; the review CSV is
never imported during startup. Check `http://localhost:8080/api/health/database`
and `http://localhost:8080/openapi/v1.json`.

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

Render injects `PORT`; the backend binds to it. TLS terminates at Render's
proxy. CORS is currently open to every origin for development/demo use and
should be restricted before a public production launch.
