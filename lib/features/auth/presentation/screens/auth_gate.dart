import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import 'login_screen.dart';
import 'owner_pending_screen.dart';
import '../../../customer/presentation/screens/customer_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../pump_owner/presentation/screens/pump_owner_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthRepository().authChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (authSnapshot.hasError) {
          return const _MessageScreen(
            message: 'Could not check login status. Please try again.',
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return const _MessageScreen(
                message:
                    'Could not verify your account. Check Firestore rules and internet connection.',
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                !profileSnapshot.hasData) {
              return const _LoadingScreen();
            }

            if (!profileSnapshot.hasData) {
              return const _LoadingScreen();
            }

            final document = profileSnapshot.data!;

            if (!document.exists) {
              return const _MessageScreen(
                message:
                    'Your user profile is missing. Contact the administrator.',
              );
            }

            final profile = document.data();

            if (profile == null) {
              return const _MessageScreen(
                message: 'Your account profile is empty.',
              );
            }

            final role = profile['role']?.toString();
            final accountStatus = profile['accountStatus']?.toString();
            final ownerStatus =
                profile['ownerApplicationStatus']?.toString() ?? 'none';

            if (accountStatus != 'active') {
              return const _MessageScreen(
                message: 'This account is disabled. Contact the administrator.',
              );
            }

            // Admin role must be checked before owner application status.
            if (role == 'admin') {
              return const AdminDashboardScreen();
            }

            if (ownerStatus == 'pending' || ownerStatus == 'rejected') {
              return const OwnerPendingScreen();
            }

            if (role == 'customer' && ownerStatus == 'none') {
              return const CustomerDashboardScreen();
            }

            if (role == 'pumpOwner' && ownerStatus == 'approved') {
              return const PumpOwnerDashboardScreen();
            }

            return const _MessageScreen(
              message:
                  'Your account role is missing or not approved. Contact the administrator.',
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _MessageScreen extends StatelessWidget {
  final String message;

  const _MessageScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 52),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await AuthRepository().logout();
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
