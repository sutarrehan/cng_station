# CNGPulse file map

- `lib/main.dart`: app entry point.
- `lib/app/`: MaterialApp and theme.
- `lib/core/`: colors, constants and reusable widgets.
- `lib/features/auth/`: Firebase login, registration, password reset and role gate.
- `lib/features/customer/`: customer dashboard, stations, tokens and vehicle profile.
- `lib/features/admin/`: pump-owner dashboard, station management and queue management.
- `lib/features/shared/models/`: shared station and token models.
- `firestore.rules`: database authorization rules.
- `functions/`: trusted server-side Firebase functions.
- `ai_service/`: optional wait estimate API.

See `README_CNGPULSE_FULL_CODE.md` for setup and limitations.
