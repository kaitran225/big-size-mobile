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

The current migrations add product sale pricing/currency, category gender,
and ASP.NET Identity tables. Applying them does **not** import the review CSV.

```powershell
dotnet tool install --global dotnet-ef --version 10.0.4
dotnet ef database update --project Backend\Backend.csproj
dotnet run --project Backend\Backend.csproj
```

The API listens on `http://localhost:5047` in the `http` launch profile.
OpenAPI is available at `/openapi/v1.json` in Development, and PostgreSQL
readiness is checked at `/api/health/database`.

## Catalogue CSV review (not seeded)

`Backend\Mock\Uniqlo Products.csv` is the supplied source. Regenerate the
review-only file with:

```powershell
.\Backend\Mock\prepare-products.ps1
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
availability maps to a mock stock quantity of 8 or 0.

Please review `BigFitProducts.review.csv` before a separate import is planned.
No CSV rows are currently auto-imported or seeded into PostgreSQL.

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
`flutter_secure_storage`. The bag is a local UI demo; cart/order/checkout
services are not implemented yet.

For Android Emulator, the default API URL is `http://10.0.2.2:5047/api`; for
Flutter Web it is `http://localhost:5047/api`. Override with
`--dart-define=API_BASE_URL=https://<your-api-host>/api` when needed. Android
cleartext traffic is enabled only in the debug manifest.
