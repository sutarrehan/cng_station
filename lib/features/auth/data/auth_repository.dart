import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String accountType = 'customer',
    String? stationName,
    String? stationAddress,
  }) async {
    if (!['customer', 'pumpOwner'].contains(accountType)) {
      throw ArgumentError('Unsupported account type.');
    }
    if (accountType == 'pumpOwner' &&
        ((stationName ?? '').trim().length < 2 ||
            (stationAddress ?? '').trim().length < 5)) {
      throw ArgumentError('Enter the station name and full station address.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    final userRef = _db.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    // A client can only create a customer profile. Owner access is granted only
    // by the trusted approvePumpOwner callable after an authorized admin review.
    await userRef.set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': 'customer',
      'accountStatus': 'active',
      'ownerApplicationStatus': accountType == 'pumpOwner' ? 'pending' : 'none',
      'createdAt': now,
      'updatedAt': now,
    });

    if (accountType == 'pumpOwner') {
      await _db.collection('pumpOwnerApplications').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'stationName': stationName!.trim(),
        'stationAddress': stationAddress!.trim(),
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  Future<void> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<String?> roleFor(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      final user = _auth.currentUser;
      if (user == null || user.uid != uid) return null;
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': (user.displayName ?? '').trim().isEmpty
            ? 'CNGPulse Customer'
            : user.displayName!.trim(),
        'email': (user.email ?? '').trim().toLowerCase(),
        'phone': '',
        'role': 'customer',
        'accountStatus': 'active',
        'ownerApplicationStatus': 'none',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'customer';
    }
    final data = doc.data();
    if (data?['accountStatus'] == 'disabled') return null;
    final role = data?['role'];
    return role is String ? role : null;
  }

  Future<String?> ownerApplicationStatusFor(String uid) async {
    final profile = await _db.collection('users').doc(uid).get();
    return profile.data()?['ownerApplicationStatus'] as String?;
  }
}
