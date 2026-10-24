# CNGPulse – Full-code starter

Flutter app with Firebase Authentication/Firestore-backed login, customer screens, admin station and queue screens, Firestore rules, Firebase Cloud Functions, and an optional FastAPI wait estimate service.

## Before running Flutter
1. Install Flutter and verify with `flutter doctor`.
2. From this directory run `flutter pub get`.
3. Install FlutterFire CLI if needed, then run `dart pub global activate flutterfire_cli`.
4. Run `flutterfire configure` and select your Firebase project/platforms. Enable Email/Password in Firebase Authentication.
5. Create a Firestore database. Deploy rules with `firebase deploy --only firestore:rules`.
6. In Firestore, create an initial authorized pump-owner user document manually at `users/<AUTH_UID>` with `role: "admin"` and profile fields. Registration intentionally creates customer role only; users cannot self-assign admin.
7. Run `flutter analyze`, then `flutter run`.

## Data collections
- `users/{uid}`: name, email, phone, role (`customer` or authorized `admin`), optional vehicle map.
- `stations/{stationId}`: name, address, active, availability (`available`, `limited`, `unavailable`), pricePerKg, queueCount. Queue/availability are operator-reported.
- `tokens/{tokenId}`: customerId, stationId, stationName, tokenNumber, position, status, createdAt.
- `complaints/{complaintId}`: customerId, body, optional image URL, status, createdAt.

## Cloud Functions
From `functions/`, run `npm install`; from project root deploy with `firebase deploy --only functions`. Functions include token creation and station update operations. Keep payment verification and secret keys on the server; payment UI/settlement is not activated in this starter.

## Optional AI service
```bash
cd ai_service
python -m venv .venv
# activate the environment
pip install -r requirements.txt
uvicorn main:app --reload
```
POST `/predict-wait` with `queue_count`, `average_service_minutes`, and `active_pumps`. This is a transparent heuristic, not a trained model. Train and validate a model only after enough historical observations are available.

## Important limitations
- Google Maps and location-based station distance/navigation UI are not wired into this first implementation; the dependency is included for the next integration stage.
- Supabase Storage and Razorpay are not wired into the UI. Configure credentials and server-side verification before using either.
- No production guarantee: run analyzer/tests, review security rules, and test on Firebase Emulator before deployment.
- Do not put service-account keys, Razorpay secret keys, or privileged credentials in the Flutter app.
