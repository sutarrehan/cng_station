# CNGPulse — Milestone 4 integration plan

This ZIP adds the missing separate Pump Owner dashboard route and connects it to AuthGate. The project README identifies the following broader work as remaining; these items are not claimed complete merely by this dashboard update.

## Dashboard changes in this update
- Admin role routes to `AdminDashboardScreen`.
- Approved Pump Owner role routes to the new `PumpOwnerDashboardScreen`.
- Pending/rejected applicants continue to use `OwnerPendingScreen`.
- Owner dashboard displays station and waiting-token counts and links to station/queue management.
- New customer tokens now copy station owner ID and station name from the station record so owner-scoped queue queries can find them.

## Milestone 4 backlog to confirm against requirements
1. Harden queue operations: server/trusted validation, consistent station ownership, token numbering and transaction/race handling.
2. Google Maps: configure keys, store coordinates, map/list discovery and directions.
3. Storage: configure Supabase Storage credentials and bucket policies before wiring complaint/station image uploads.
4. Payments: trusted Razorpay order creation and server-side signature verification.
5. FCM: token registration, secure notification triggers and delivery testing.
6. AI wait prediction: connect the existing Python service only after defining data schema, endpoint configuration and evaluation metrics.
7. Add widget/integration tests for admin, owner approval, customer login, station ownership and queue status transitions.

## Verification needed
Run `flutter pub get`, `dart format lib`, `flutter analyze`, `flutter test` and manual Firebase testing in the target project. Review and deploy Firestore rules/indexes deliberately. Firebase Cloud Functions and trusted payment/notification workflows may require Blaze billing; do not assume they work on Spark without verifying current Firebase constraints.

## Additional implementation scaffold
- Added `MapsService` helpers for marker construction and Google Maps search/directions URLs.
- Added `NotificationService` for permission, FCM token registration to the signed-in user's profile, refresh updates, and foreground-message stream.
- Added configuration gates for Supabase and Razorpay rather than silently faking payment/upload success.
- Added `FEATURE_IMPLEMENTATION_MATRIX.md` and `.env.example` to track the image feature scope and required external configuration.

These are partial integration steps, not proof that every illustrated feature is complete. Supabase upload transport, device GPS plugin setup, Razorpay checkout and trusted server-side verification remain explicitly gated.


## Phase 1 foundation work (updated)
- Added `geolocator`, `supabase_flutter`, and `url_launcher` dependencies to `pubspec.yaml`.
- Implemented device location permission/service checks in `LocationService`.
- Added Android coarse/fine and iOS when-in-use location permission declarations.
- Added optional Supabase initialization via `--dart-define` in `AppInitializer`.
- Implemented complaint-image upload to a user-scoped Supabase path with a short-lived signed URL. Keep the bucket private and configure Storage RLS before using real user uploads.
- Razorpay remains intentionally gated until a trusted order creation/signature-verification backend exists; never place a Razorpay secret in Flutter.
- Flutter analysis/tests still need to be run in an environment with Flutter SDK after `flutter pub get`.
