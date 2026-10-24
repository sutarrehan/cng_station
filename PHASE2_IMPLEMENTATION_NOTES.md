# CNGPulse Phase 2 — Authentication & Profile

## Implemented in this phase
- Added a customer Profile tab to the customer dashboard.
- Profile details are streamed from `users/{uid}` in Firestore.
- Signed-in users can update their own name and phone using the existing `FirestoreService.updateMyProfile` method.
- Added validation for the name and optional phone number on the profile form.
- Tightened registration phone validation to accept 10–13 digits, optionally prefixed by `+`.
- Kept existing email/password Firebase Auth login, registration, password reset, owner pending and role-based routing flows intact.

## Setup / verification
Run from project root:

```powershell
flutter pub get
flutter analyze
flutter test
```

## Notes / not claimed as complete
- Firebase email/password auth and password-reset flow exist; phone OTP is not implemented in this phase.
- This environment does not have the Flutter SDK, so compilation/tests were not run here.
- Firestore security rules must be deployed to the same Firebase project for profile updates to work.
