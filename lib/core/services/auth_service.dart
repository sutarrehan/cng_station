import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/auth_repository.dart';

/// Application-facing Firebase Authentication service.
/// Profile roles and approvals are read from Firestore by AuthGate; clients
/// must never assign themselves an admin or approved pump-owner role.
class AuthService {
  AuthService({AuthRepository? repository}) : _repository = repository ?? AuthRepository();
  final AuthRepository _repository;

  User? get currentUser => _repository.currentUser;
  Stream<User?> get authChanges => _repository.authChanges;

  Future<void> signIn({required String email, required String password}) =>
      _repository.login(email, password);

  Future<void> signUp({required String name, required String email, required String phone,
    required String password, String accountType = 'customer', String? stationName,
    String? stationAddress}) => _repository.register(
      name: name, email: email, phone: phone, password: password,
      accountType: accountType, stationName: stationName, stationAddress: stationAddress);

  Future<void> sendPasswordReset(String email) => _repository.resetPassword(email);
  Future<void> signOut() => _repository.logout();
}
