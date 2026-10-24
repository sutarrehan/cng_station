# CNGPulse — Milestone 2 + Admin/Milestone 3 update

## Added in this update
- One shared login flow; Firestore `users/{uid}.role` determines the dashboard.
- Admin dashboard metrics for pending/approved/rejected Pump Owner applications.
- Pump Owner Applications screen with Pending, Approved and Rejected tabs.
- Applicant detail review and Accept/Reject actions, including required rejection reason.
- Spark-compatible application review: client Firestore transaction protected by Firestore Security Rules; the admin account must be provisioned manually in Firebase Console.
- AuthGate now listens to the user profile document so approval/rejection status changes route automatically without repeatedly recreating FutureBuilders.
- Rejected applicants see the rejection reason; approved owners route to the Pump Owner dashboard.
- Admin dashboard includes a customer complaints list entry.
- Station availability updates no longer require a callable Cloud Function in the station management screen.

## Admin account setup
1. Create the admin user in Firebase Authentication.
2. In Firestore `users`, create a document whose document ID equals the Auth UID.
3. Use exact case-sensitive fields, especially `accountStatus` (capital S):
   - `uid`: the Authentication UID
   - `name`: `CNGPulse Admin`
   - `email`: the admin email
   - `role`: `admin`
   - `accountStatus`: `active`
   - `ownerApplicationStatus`: `none`
4. Do not create an admin via the public app registration screen.

## Important Firebase step
Deploy the updated `firestore.rules` from this project. Existing deployed rules will not change automatically when this ZIP is extracted. From the project directory run:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

This review flow is designed to work without deploying Cloud Functions, for the Firebase Spark plan. Other existing app features that call Cloud Functions may still require their own Spark-compatible implementation or a plan change; they are not claimed as completed by this update.

## Run and verify
```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Test with separate accounts: a manually provisioned admin account, a new Pump Owner application, and a customer account. Verify a pending owner cannot access station management, approve/reject from the admin account, and confirm the owner's screen updates after the profile changes.
