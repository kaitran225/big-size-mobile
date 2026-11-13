# BigFit Flutter app

## API connection

The app uses the Render backend by default:

`https://big-fit-pgm-store.onrender.com/api`

The app appends `/api` automatically. Set `API_BASE_URL` at launch to use a
different server; switching between servers signs out the current account so
its token is not sent to another server.

Local backend addresses depend on where Flutter runs:

- Flutter web and desktop: `http://localhost:5047`
- Android emulator: `http://10.0.2.2:5047`
- Physical device: use the development computer's LAN IP, for example
  `http://192.168.1.20:5047`, and make sure the device can reach that port.

You can also override the initial server when launching:

```powershell
flutter run --dart-define=API_BASE_URL=https://big-fit-pgm-store.onrender.com
```

For a local backend, use `http://localhost:5047` on desktop and web,
`http://10.0.2.2:5047` on the Android emulator, or the development computer's
LAN address on a physical device.

## Realtime notifications

After login the app connects to `{origin}/hubs/notifications` with the JWT
query parameter. The notifications screen shows whether the hub is connected.
Staff accounts call `SubscribeStaff` to hear `newOrder` events.

## Demo flows

See [docs/demo-script.md](../docs/demo-script.md) for customer vs staff walkthroughs.

## OpenAPI / Swagger

The deployed API does not map a homepage or a Swagger UI at `/swagger`, so those
URLs return 404. Its OpenAPI document is available at
<https://big-fit-pgm-store.onrender.com/openapi/v1.json>. The Flutter app uses
the API base URL above, not the OpenAPI document URL.
