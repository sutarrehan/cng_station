# CNGPulse project structure

This archive was created from the uploaded Flutter project, preserving existing files and adding feature folders/placeholders for the CNGPulse application.

## Roles
- Customer
- Admin / Pump Owner

## Main stack
- Flutter + Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Cloud Messaging
- Google Maps Platform
- Razorpay
- Supabase Storage
- Optional Python AI service for waiting-time prediction and best-time recommendation

## Important
- Placeholder files are not complete implementations.
- Review dependency versions before adding packages to `pubspec.yaml`.
- Keep payment secrets and Supabase service-role keys on trusted backend only.
- Replace default Firestore rules with tested role-based rules before deployment.
