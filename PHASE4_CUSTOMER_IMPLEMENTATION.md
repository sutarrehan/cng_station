# CNGPulse Customer Phase 4 additions

## UI preservation
Existing dashboard, stations, tokens, vehicle, and profile screens were preserved. One `Customer Services` quick-action card was added to the existing dashboard to open the new customer tools screen.

## Added customer tools
- Email verification request from Firebase Auth
- Vehicle collection CRUD, edit, delete, primary selection
- Profile edit view
- Token history with QR display, status, queue fields and waiting-token cancellation
- Refueling log and basic km/kg efficiency calculation
- Fuel reminder records (scheduled notifications still require a trusted scheduler/backend)
- Active offers listing
- Complaint submit and status tracking
- Station ratings/reviews
- Destination search via external Google Maps web search (no embedded Maps billing/API key)
- Active station price/queue comparison
- Current low-queue heuristic (not a trained AI forecast)
- FCM token registration rules updated to permit own-device token registration
- Sequential per-station token number transaction and approximate queue position
- Firestore rules for newly used collections

## Required local steps
1. Run `flutter pub get` (adds `qr_flutter`).
2. Review `firestore.rules` and deploy it to the correct Firebase project.
3. Run `flutter analyze`, then `flutter test`, then run on web/mobile.
4. Verify the signed-in user's rules against the app's actual Firestore profile schema.

## Important limitations
- Razorpay checkout remains intentionally disabled until a trusted backend creates orders and verifies payment signatures. Do not mark a payment paid from the Flutter client.
- Sequential numbering is implemented with a Firestore transaction and a rule that only permits a +1 counter increment. This is safer than a client-side read-then-write but still allows signed-in clients to consume a number; production anti-abuse requires a trusted backend.
- `queuePosition` is an estimate from the station's current `queueCount`, not an exact live rank. Exact queue position should be maintained by station operations or a trusted backend.
- QR contains a token reference. QR rendering is not equivalent to secure station-side token validation.
- Email verification is available as a customer action; existing register/login flow should still be tested to decide whether unverified users are blocked.
- Reminder records are saved, but scheduled push delivery requires a scheduler/backend.
- AI/best-time is a transparent heuristic using current queue data, not trained prediction.
- Firestore indexes may be requested by Firebase at runtime depending on the queries and existing project indexes.

This archive was edited from the supplied Phase 3 project. Flutter SDK/analyzer was not available in this environment, so no compile/test success is claimed.
