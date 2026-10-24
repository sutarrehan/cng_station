# CNGPulse implementation status — Milestone 1

This project is being completed in verifiable milestones. This ZIP contains the first milestone changes; it is not yet a production-complete application.

## Implemented in this milestone

- Firebase initialization uses `DefaultFirebaseOptions.currentPlatform` in `lib/main.dart`.
- Login screen has separate Customer Login and Pump Owner Login selection.
- Login checks the account role after Firebase authentication. Customers must have `role: customer`; Pump Owners must have `role: admin`. Role selection does not grant permissions.
- Missing legacy profiles are repaired as customers only; this path cannot grant Pump Owner access.
- Station records include the signed-in owner UID. Firestore rules restrict station creation/update/deletion to an approved admin-role user and their own station records.
- Existing customer registration creates a customer profile.

## Provisioning the first Pump Owner securely

There is intentionally no public self-service way to promote an account to Pump Owner. To authorize a first owner for development, create the user through Firebase Authentication, then create/update `users/{AUTH_UID}` in Firestore using a trusted project administrator account or the Firebase Console. Set at minimum:

- `uid`: exact Firebase Authentication UID (string)
- `name`: owner's name (string)
- `email`: account email (string)
- `phone`: phone number (string)
- `role`: `admin` (string)
- `accountStatus`: `active` (string)
- `createdAt`: timestamp
- `updatedAt`: timestamp

Do not give customers Firestore Console access. Never expose privileged service-account credentials in the Flutter app. This initial manual provisioning is a development bootstrap; a production owner approval workflow should be implemented with a trusted Cloud Function and documented business verification.

## Firebase setup

1. Enable Email/Password under Firebase Authentication → Sign-in method.
2. Create Cloud Firestore in the `cong-pulse` project.
3. Review `firestore.rules` and `firestore.indexes.json`.
4. From the project root, run `firebase use cong-pulse`.
5. Deploy rules only after reviewing them: `firebase deploy --only firestore:rules`.
6. Run `flutter pub get`, `dart format .`, `flutter analyze`, and `flutter test`.

## Still incomplete / requires later milestones

- A self-service Pump Owner application and trusted approval workflow.
- Full station-owner scoped queue/booking backend and race-safe queue numbering.
- Full Google Maps key setup and live station location UX.
- Supabase Storage integration and storage policies.
- Razorpay trusted order creation and server-side payment verification.
- FCM notification triggers and delivery testing.
- AI training pipeline with real historical queue data.
- Full integration/device tests and production deployment review.

No claim is made that these remaining integrations have been tested or completed.
