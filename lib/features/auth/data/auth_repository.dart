import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> register(
      {required String name,
      required String email,
      required String phone,
      required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await credential.user!.updateDisplayName(name.trim());
    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': 'customer',
      'accountStatus': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login(String email, String password) async =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> logout() => _auth.signOut();
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<String?> roleFor(String uid) async {
    final ref = _db.collection('users').doc(uid);
    var doc = await ref.get();
    // Repair a missing profile for an authenticated legacy account as a CUSTOMER only.
    // This never grants admin access; Firestore rules permit self-creation only as customer.
    if (!doc.exists) {
      final user = _auth.currentUser;
      if (user == null || user.uid != uid) return null;
      await ref.set({
        'uid': uid,
        'name': (user.displayName ?? '').trim().isEmpty ? 'CNGPulse Customer' : user.displayName!.trim(),
        'email': (user.email ?? '').trim().toLowerCase(),
        'phone': '',
        'role': 'customer',
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      doc = await ref.get();
    }
    final data = doc.data();
    if (data?['accountStatus'] == 'disabled') return null;
    final role = data?['role'];
    return role is String ? role : null;
  }
}
