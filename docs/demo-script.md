# BigFit demo script

## Customer

1. Register or sign in (JWT stored securely).
2. Open **Account security** → request email verification or OTP (with SMTP off, copy dev hints / check server logs).
3. Browse catalog → **AI stylist** → use a recommendation chip to add a variant to the bag.
4. Checkout with COD or SePay sandbox transfer; watch **Notifications** (SignalR live banner).
5. Open **Orders** → order detail reflects server status; staff updates refresh via hub.

## Staff / admin

1. Sign in as `StoreStaff` or bootstrap admin.
2. **Shipment tracker** / **Store management → Orders** loads `/api/fulfillment/orders` (all customers).
3. **Accept** (`Pending` COD or `Confirmed` prepaid) → **Ship** → **Delivered**; customer receives notifications and hub events.

## Wiring checklist

| Feature | You configure |
|--------|----------------|
| Email / OTP | `Email__Enabled=true` and SMTP env vars on Render |
| AI | `Ai__OpenAiCompatible__*` |
| Payments | SePay sandbox keys (existing README) |
| Realtime | Automatic when signed in (hub `/hubs/notifications?access_token=`) |
