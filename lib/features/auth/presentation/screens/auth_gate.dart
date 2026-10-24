import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_repository.dart';
import 'login_screen.dart';
import '../../../customer/presentation/screens/customer_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false, _failed = false;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Firebase is initialized in lib/main.dart with generated platform options.
      // This gate only handles authentication state and role-based routing.
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_failed) {
      return Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.settings_suggest_outlined,
                        size: 54, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text('Firebase setup required',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Run `flutterfire configure` and add the generated Firebase configuration, then restart the app.',
                        textAlign: TextAlign.center),
                  ]))));
    }
    return StreamBuilder<User?>(
        stream: AuthRepository().authChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null) return const LoginScreen();
          return FutureBuilder<String?>(
              future: AuthRepository().roleFor(user.uid),
              builder: (context, roleSnap) {
                if (roleSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                if (roleSnap.hasError) {
                  return const _AccessDenied(
                      message:
                          'Could not verify your account role. Check your connection and try again.');
                }
                switch (roleSnap.data) {
                  case 'customer':
                    return const CustomerDashboardScreen();
                  case 'admin':
                    return const AdminDashboardScreen();
                  default:
                    return const _AccessDenied(
                        message:
                            'Your account role is missing or not approved. Contact the station administrator.');
                }
              });
        });
  }
}

class _AccessDenied extends StatelessWidget {
  final String message;
  const _AccessDenied({required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.gpp_bad_outlined, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () => AuthRepository().logout(),
                    child: const Text('Sign out'))
              ]))));
}
