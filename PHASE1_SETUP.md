# CNGPulse Phase 1 setup

## 1. Install dependencies
Run from the project root:

```bash
flutter pub get
```

## 2. Optional Supabase configuration
Use the Supabase project URL and public anon key only. Never use a service-role key in the app.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY \
  --dart-define=SUPABASE_COMPLAINT_BUCKET=complaint-images
```

Create a **private** Storage bucket named `complaint-images` (or your chosen name). Add Storage RLS policies so authenticated users can only upload/read objects under their own UID folder. The app uploads to `<uid>/complaints/<timestamp>.<ext>` and returns a signed URL valid for one hour. Do not treat the signed URL as a permanent record; persist the object path and generate a fresh signed URL when displaying the image.

## 3. Device location
Android coarse/fine and iOS when-in-use descriptions were added. Test the permission flow on a real device and ensure users can still browse stations when they decline location permission.

## 4. Maps / payment / push
- Maps helper currently builds station markers and Google Maps directions/search URLs. Add restricted platform API keys before rendering native map tiles.
- FCM token registration helper exists; verify Firestore rules allow only the signed-in user to update their own token fields. Sending notifications requires a trusted sender/backend.
- Razorpay checkout is intentionally blocked until server-created orders and server-side signature verification are configured. Do not add `key_secret` to Dart or `.env` bundled into the app.

## 5. Verify
Run `flutter analyze` and `flutter test` after dependencies resolve. These commands were not run while preparing this phase because Flutter SDK is not available in the editing environment.
