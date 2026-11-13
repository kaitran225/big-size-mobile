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

### Email, OTP, fulfilment, and realtime

- **Email / OTP** — set `Email__Enabled=true` and SMTP variables from
  `.env.example`. When disabled, verification links and OTP codes are written to
  application logs for demos.
- **Staff orders** — `GET/PATCH /api/fulfillment/orders` (Admin or StoreStaff).
  Actions: `accept`, `ship`, `complete`.
- **SignalR** — hub at `/hubs/notifications?access_token={jwt}`; events
  `notificationCreated`, `orderStatusChanged`, and staff `newOrder`.

### SePay sandbox

The backend runs on Render (`https://big-fit-pgm-store.onrender.com`) and the
Flutter app talks to it, so SePay must call the **public** domain. Nothing in
this flow works against `localhost`.

Endpoints used (verified against `https://developer.sepay.vn/en/bankhub`):

| Step | Bank Hub API | Used by |
| --- | --- | --- |
| Access token | `POST {ApiBaseUrl}/v1/token`, Basic `client_id:client_secret`, returns `access_token` + `ttl` | every sandbox call |
| Linked accounts | `GET {ApiBaseUrl}/v1/bank-account?page=1&per_page=20` → `data[].{xid,bank_code,bank_bin,account_number,account_holder_name,active}` | checkout transfer details |
| Mock credit (sandbox only) | `POST {ApiBaseUrl}/v1/transaction/create` with `bank_account_xid`, `transfer_type: "credit"`, `amount`, `transaction_content` | the app's demo button |
| IPN callback | SePay posts the flat balance-change payload to `{PublicBaseUrl}/api/payments/sepay/ipn` with header `Authorization: Apikey {NotifyApiKey}` | payment confirmation |

`ApiBaseUrl` is `https://bankhub-api-sandbox.sepay.vn`. Catalog prices stay in
EUR; the order total is converted to VND with `Payments:SePay:EurToVndRate`
(default 27000). Cash on delivery never calls SePay.

**Configured on Render** (sync: false in `render.yaml`, so set them in the
dashboard): `Payments__SePay__ClientId`, `Payments__SePay__ClientSecret`,
`Payments__SePay__IpnSecretKey`, and optionally
`Payments__SePay__BankAccountXid`. `Payments__SePay__PublicBaseUrl` and
`Payments__SePay__ApiBaseUrl` already ship in `render.yaml`.

**Configured on the SePay Bank Hub sandbox page**: Notify URL =
`https://big-fit-pgm-store.onrender.com/api/payments/sepay/ipn`, Notify API Key
= the same value as `Payments__SePay__IpnSecretKey`.

Check the deployment without guessing:

```
GET https://big-fit-pgm-store.onrender.com/api/payments/sepay/status   (Bearer JWT)
```

It reports `configured`, which of `hasClientId` / `hasClientSecret` /
`hasIpnSecretKey` / `hasBankAccountXid` are present, the exact Notify URL to
paste into SePay, the linked account it can reach, and an `error` naming the
broken step (settings missing, credentials rejected, or no active account).
It never returns secrets.

Demo flow: checkout with bank transfer → the app shows the VND amount, bank,
account number, transfer content (the order number) and a VietQR code → the
"S simulate sandbox payment" button asks Bank Hub to create a matching credit →
SePay posts the IPN → the backend matches the order by `content` (exact, then
substring), compares the amount, marks the payment `Succeeded` and confirms the
order. The simulate request waits up to 3s for that IPN and only falls back to
confirming locally (with a warning log) if the callback never arrives, so a
misconfigured Notify URL shows up in the logs instead of silently passing.

Sandbox test account for linking (from the SePay docs): MBBank, phone
`0000000001`, holder `NGUYEN VAN A`, CCCD `001234567890`, account
`0123456789`, OTP `12345678`. A repeated `transaction_id` never overwrites a
payment that already succeeded.

Locally, if you ever run the backend, set the same keys with user secrets from
`Server`:

```powershell
dotnet user-secrets set "Payments:SePay:ClientId" "YOUR_BANK_HUB_CLIENT_ID" --project Backend
dotnet user-secrets set "Payments:SePay:ClientSecret" "YOUR_BANK_HUB_CLIENT_SECRET" --project Backend
dotnet user-secrets set "Payments:SePay:IpnSecretKey" "YOUR_NOTIFY_API_KEY" --project Backend
dotnet user-secrets set "Payments:SePay:BankAccountXid" "YOUR_LINKED_ACCOUNT_XID" --project Backend
```
