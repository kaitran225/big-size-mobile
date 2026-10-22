# BigFit Flutter app

## API connection

The app uses the Render backend by default:

`https://big-fit-pgm-store.onrender.com/api`

Use the server icon in the storefront app bar to switch between Render and the
local development backend. The selected server is saved on the device. Switching
servers signs out the current account so its token is not sent to another server.

The app appends `/api` automatically, so enter a server origin such as
`https://big-fit-pgm-store.onrender.com` or `http://localhost:5047`.

Local backend addresses depend on where Flutter runs:

- Flutter web and desktop: `http://localhost:5047`
- Android emulator: `http://10.0.2.2:5047`
- Physical device: use the development computer's LAN IP, for example
  `http://192.168.1.20:5047`, and make sure the device can reach that port.

You can also override the initial server when launching:

```powershell
flutter run --dart-define=API_BASE_URL=https://big-fit-pgm-store.onrender.com
```

## OpenAPI / Swagger

The deployed API does not map a homepage or a Swagger UI at `/swagger`, so those
URLs return 404. Its OpenAPI document is available at
<https://big-fit-pgm-store.onrender.com/openapi/v1.json>. The Flutter app uses
the API base URL above, not the OpenAPI document URL.
