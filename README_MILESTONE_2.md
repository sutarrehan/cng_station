# CNGPulse — Milestone 2: Pump Owner Applications and Station Management

## Included in this milestone

- Registration can be Customer or Pump Owner.
- Pump Owner registration collects a proposed station name and address.
- New owner applications are stored in `pumpOwnerApplications/{uid}` with `status: pending`.
- The user profile remains `role: customer` while pending; the client cannot assign itself `pumpOwner` or `admin`.
- AuthGate shows the application-pending screen while approval is pending.
- An existing authorized `admin` account can review pending applications in the Pump Owner Dashboard.
- Approval/rejection is performed by the callable Cloud Function `reviewPumpOwnerApplication`; the Admin SDK writes the role and application state.
- Approved accounts are assigned `role: pumpOwner` and route to station operations.
- Pump Owners can create stations owned by their UID, edit station name/address/price, update availability, and deactivate their own station.
- Firestore rules restrict station writes to an approved owner of that station or an admin.
- Firestore indexes include the pending-application query.

## Important role/security setup

The app intentionally does not allow anyone to self-assign `admin`. Before deploying this milestone, ensure at least one trusted administrator exists. Use Firebase Console or a trusted Admin SDK script to set an already authenticated, trusted account's `users/{uid}` document to:

```json
{
  "role": "admin",
  "accountStatus": "active",
  "ownerApplicationStatus": "none"
}
```

Use the actual Firebase Authentication UID. Never publish an Admin SDK service-account key or put it in Flutter. Firestore Console/Admin SDK operations bypass Firestore rules; only trusted project owners should do this bootstrap step.

## Deploy backend changes

From the project root, after installing Node.js 20 and Firebase CLI and logging into the correct account:

```powershell
firebase use cong-pulse
cd functions
npm install
cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Cloud Functions deployment may require the Firebase project to be on a billing-enabled plan. Confirm the target project before deploying.

## Run Flutter app

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

## Manual end-to-end verification

1. Register a customer. Confirm Authentication user and `users/{uid}` are created with `role: customer`.
2. Register a Pump Owner with station name/address. Confirm the profile has `ownerApplicationStatus: pending` and `pumpOwnerApplications/{uid}` has `status: pending`.
3. Sign in as the trusted admin account and open Pump Owner Applications.
4. Approve the application. Confirm Cloud Function changes profile role to `pumpOwner` and application status to `approved`.
5. Sign in as the approved Pump Owner. Create a station and confirm `ownerId` equals the owner UID.
6. Edit station details, change availability, and deactivate it. Confirm Firestore updates.
7. Try changing `users/{uid}.role` from the client as a customer; the operation must be denied.
8. Try editing another owner's station; the operation must be denied.

## Limitations / honest test status

This environment did not have Flutter/Dart SDK available, so `flutter analyze`, `flutter test`, Android builds, Firebase Emulator tests, and deployed Cloud Function tests were not run here. Run the commands above locally and review the output. The admin approval function must be deployed before approvals will work in the app. Some existing dashboard/queue features from earlier milestones may still require further role-scoped integration.
