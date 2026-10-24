# VÔL Admin (Flutter)

The VÔL admin panel, rebuilt in Flutter Web. It uses the same NestJS API as the Next.js apps in
`Vol_Webapp` (`apps/api`) and is a screen-for-screen port of `apps/admin`, so a change to one is easy
to carry over to the other.

## Running locally

The panel talks to the live Railway API (`https://volwebapp-production.up.railway.app`) by default.
Railway only accepts origins listed in its `CORS_ORIGINS`, so for local work run the API from the
Vol_Webapp repo (`npm run dev:api`), add `http://localhost:5001` to `CORS_ORIGINS` in `apps/api/.env`
once, and point the panel at it:

```bash
flutter pub get
flutter run -d chrome --web-port 5001 --dart-define=API_URL=http://localhost:4000
```

Sign-in is email + password, then a 6-digit code (`/auth/admin/login` → `/auth/admin/verify`). Only
`ADMIN` and `MODERATOR` accounts get in; Security Center and Settings are `ADMIN`-only. The panel uses
the admin refresh cookie, so signing in here never touches a user-app session in the same browser.

## Layout

```
lib/core          API client (admin scope: bearer token in memory, refresh via the admin cookie),
                  auth state, query cache, browser helpers (sessionStorage, CSV download), formatting
lib/models        admin response shapes from packages/api-client/src/types.ts
lib/theme         VÔL and admin tokens, dark theme
lib/ui            shared widgets ported from components/ui and components/modals
lib/charts        growth, activity and share charts (custom painted, replacing Recharts)
lib/features      auth, shell (sidebar + top bar), dashboard, users, cases, analytics, security,
                  settings, policies (terms / privacy)
lib/router.dart   every route from apps/admin plus the staff-only redirects
```

Like the Next.js panel, desktop windows narrower than 1920px are zoomed to keep Figma's proportions
(`FigmaZoom` in `lib/ui/layout.dart`).

When the API changes a response shape, update the matching model in `lib/models/admin.dart`.

flutter_svg can't draw nested `<svg>` elements, so icons copied from `apps/admin/public` that use them
were rewritten with `<g transform>`. Do the same for any new icon that renders blank.

## Deploying

Vercel deploys straight from this repository. Vercel has no Flutter, so `vercel.json` clones the
pinned Flutter release during install, builds `build/web`, and sends every path to `index.html` so
deep links work. In the Vercel project, leave the framework preset on "Other" and the build settings
empty; `vercel.json` sets them.

Builds call the Railway API. Add the deployed URL to `CORS_ORIGINS` on Railway, or the panel
loads but can't sign in ("Can't reach the server").

`.github/workflows/check.yml` runs `flutter analyze` and `flutter test` on every push.

```bash
flutter analyze
flutter test
flutter build web --release --wasm --pwa-strategy=none
```
