import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String _loginAs = 'customer';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = AuthRepository();

      await auth.login(
        _email.text.trim(),
        _password.text,
      );

      final user = auth.currentUser;

      if (user == null) {
        throw Exception('Login succeeded but user session was not found.');
      }

      final role = await auth.roleFor(user.uid);
      final ownerStatus = await auth.ownerApplicationStatusFor(user.uid);

      // Admin can sign in regardless of the selected Customer/Pump Owner option.
      final roleAllowed = role == 'admin' ||
          (_loginAs == 'pumpOwner' ? role == 'pumpOwner' : role == 'customer');

      if (!roleAllowed) {
        // Keep pending/rejected pump-owner applicants signed in so AuthGate
        // can show their application status.
        final isOwnerApplicant = _loginAs == 'pumpOwner' &&
            (ownerStatus == 'pending' || ownerStatus == 'rejected');

        if (!isOwnerApplicant) {
          await auth.logout();
        }

        if (!mounted) return;

        final message = _loginAs == 'pumpOwner'
            ? ownerStatus == 'pending'
                ? 'Your Pump Owner application is awaiting admin approval.'
                : ownerStatus == 'rejected'
                    ? 'Your Pump Owner application was rejected. Please contact the administrator.'
                    : 'This account is not an approved Pump Owner account. Please register as Pump Owner to apply.'
            : 'This account is registered for Pump Owner access. Please choose Pump Owner Login.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      // On successful login, AuthGate listens to Firebase auth state and
      // opens the appropriate dashboard. Do not manually navigate here.
    } catch (error) {
      if (!mounted) return;

      final errorText = error.toString();
      String message = 'Login failed. Please try again.';

      if (errorText.contains('invalid-credential') ||
          errorText.contains('wrong-password') ||
          errorText.contains('invalid-email')) {
        message = 'Email or password is incorrect.';
      } else if (errorText.contains('user-not-found')) {
        message = 'Account not found.';
      } else if (errorText.contains('network-request-failed')) {
        message = 'Check your internet connection.';
      } else if (errorText.contains('permission-denied')) {
        message =
            'Could not read your account profile. Check Firestore security rules.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        size: 36,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your account type to continue.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    _LoginRoleCard(
                      selected: _loginAs == 'customer',
                      icon: Icons.person_outline_rounded,
                      title: 'Customer Login',
                      subtitle: 'Find stations and book tokens',
                      onTap: () {
                        setState(() => _loginAs = 'customer');
                      },
                    ),
                    const SizedBox(height: 10),
                    _LoginRoleCard(
                      selected: _loginAs == 'pumpOwner',
                      icon: Icons.local_gas_station_rounded,
                      title: 'Pump Owner Login',
                      subtitle: 'Manage your station and customer queue',
                      onTap: () {
                        setState(() => _loginAs = 'pumpOwner');
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Email address',
                      controller: _email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      controller: _password,
                      prefixIcon: Icons.lock_outline,
                      password: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: _loading
                          ? 'Signing in...'
                          : _loginAs == 'pumpOwner'
                              ? 'Login as Pump Owner'
                              : 'Login as Customer',
                      loading: _loading,
                      onPressed: _login,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Smarter stops. Shorter waits.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginRoleCard extends StatelessWidget {
  const _LoginRoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.border;

    return Material(
      color: selected ? AppColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? AppColors.green : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.green : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
