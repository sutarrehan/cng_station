# CNGPulse Phase 6 — Integration & Development Readiness

## Included in this phase

- Centralized Firestore collection names and app constants.
- Reusable email, phone, password, numeric and complaint validators.
- Mileage, fuel-cost and cost-per-km calculations with input validation.
- Firebase Authentication facade around the existing AuthRepository.
- Central route names and route generator for existing customer, owner and admin screens.
- Lightweight splash screen placeholder; role/auth gating remains in `AuthGate`.
- Basic data models for user, station/pump, token, queue, vehicle, complaint, payment, transaction/refueling, notification and AI estimate.
- Optional FastAPI wait-time and best-time rule-based estimate endpoints.
- Existing Phase 5 UI and Firebase configuration retained.

## Important boundaries

- The AI endpoints are heuristics, not trained models or live queue sensors.
- PaymentModel is data-only. Never mark payment successful from the client; verify payment using a trusted provider backend.
- Do not grant admin or approved pump-owner roles from client-side code.
- Firestore rules and transaction logic must be tested against the exact Firebase project before production use.
- Firebase native config in `android/app/google-services.json` and `lib/firebase_options.dart` is project-specific. Verify it belongs to your intended Firebase project before deployment.
- This package has not been built with Flutter in this execution environment because the Flutter/Dart SDK is unavailable here. Run the commands below on your Windows development machine.

## Windows validation

Open PowerShell in this folder:

```powershell
flutter clean
flutter pub get
 dart format lib
flutter analyze
flutter test
flutter build apk --debug
```

If `flutter analyze` reports errors, fix those before relying on a release build. Existing lint infos may remain. Test with a customer, an approved pump owner, a pending owner and an admin account.

## End-to-end test plan

1. Customer registers/logs in and profile is created.
2. Customer books a token; verify one token document and one counter increment.
3. Pump owner application is submitted and stays pending until admin review.
4. Admin approves/rejects the application; verify both application and user profile state.
5. Approved owner can edit only their own station and see only their own station's queue.
6. Owner status transition appears in the customer's token screen.
7. Unauthenticated user, customer and a different owner cannot mutate protected records.
8. Try two simultaneous bookings for the same station and confirm there are no duplicate token numbers.
9. Verify password reset, logout, disabled account, empty/error/loading states.
10. Confirm Firestore indexes and rules deploy cleanly before distributing the APK.
