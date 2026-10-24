# CNGPulse feature implementation matrix (image reference)

This matrix is the acceptance scope, not a claim that every item is already operational.

## Customer app (image features 1–29 and 31–40)
- [x] Firebase Auth login/register screens and role-based routing exist in source.
- [x] Firestore profile access, station stream, token booking/cancel transaction, complaint submission/listing service exist.
- [x] Customer dashboard, station list, tokens, vehicle screens exist.
- [x] Google Maps helper for station markers and navigation/search URLs added.
- [x] FCM permission/token registration helper added.
- [ ] OTP phone authentication, full password recovery verification, complete vehicle CRUD/history/mileage/reminders/offers/ratings, route-based pump filtering, AI best-time UI, PDF receipt and all-notification inbox require feature screens and end-to-end tests.
- [ ] Razorpay checkout requires a Razorpay key, trusted order creation, and server-side signature verification.
- [ ] Complaint image uploads require Supabase project credentials, `supabase_flutter`, and secure bucket policies.
- [ ] Device GPS requires location plugin plus Android/iOS permission configuration.

## Admin / pump owner app (image features 30 and 41–45)
- [x] Admin dashboard, owner application review, station management and queue management screens exist in source.
- [x] AuthGate separates admin, approved pump owner, pending/rejected owner and customer routes.
- [ ] Transaction reconciliation, full analytics, hourly heatmap, maintenance log, complaint resolution workflow, PDF/CSV export and end-to-end role isolation need implementation/verification.
- [ ] Push notification delivery requires trusted backend triggers; sending credentials must never be embedded in Flutter.

## Platform and verification
- [x] Firestore rules, indexes, Firebase Functions source and FastAPI wait estimate source included.
- [ ] Firebase Cloud Functions deployment may require Blaze; this project must not claim trusted payment verification or server-side notifications on Spark without an alternative trusted backend.
- [ ] Flutter SDK is unavailable in the current editing environment; `flutter analyze` and `flutter test` were not run here.
