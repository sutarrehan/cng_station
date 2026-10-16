import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _stationName = TextEditingController();
  final _stationAddress = TextEditingController();
  bool _loading = false;
  bool _accepted = false;
  String _accountType = 'customer';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _stationName.dispose();
    _stationAddress.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms to continue.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthRepository().register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        accountType: _accountType,
        stationName: _stationName.text,
        stationAddress: _stationAddress.text,
      );

      // AuthGate handles navigation after successful registration.
    } catch (error) {
      if (!mounted) return;

      String message = 'Registration failed. Please try again.';

      if (error.toString().contains('email-already-in-use')) {
        message = 'This email is already registered.';
      } else if (error.toString().contains('weak-password')) {
        message = 'Please choose a stronger password.';
      } else if (error.toString().contains('invalid-email')) {
        message = 'Enter a valid email address.';
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
      appBar: AppBar(title: const Text('Create Account')),
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
                    const Text(
                      'Join CNGPulse',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Create your CNGPulse account.'),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'customer', label: Text('Customer'), icon: Icon(Icons.person_outline)),
                        ButtonSegment(value: 'pumpOwner', label: Text('Pump Owner'), icon: Icon(Icons.local_gas_station_outlined)),
                      ],
                      selected: {_accountType},
                      onSelectionChanged: _loading ? null : (selection) => setState(() => _accountType = selection.first),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Full name',
                      controller: _name,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                    if (_accountType == 'pumpOwner') ...[
                      const SizedBox(height: 14),
                      CustomTextField(label: 'Proposed CNG station name', controller: _stationName, prefixIcon: Icons.local_gas_station_outlined, validator: (value) => _accountType == 'pumpOwner' && (value == null || value.trim().length < 2) ? 'Enter station name' : null),
                      const SizedBox(height: 14),
                      CustomTextField(label: 'Full station address', controller: _stationAddress, prefixIcon: Icons.location_on_outlined, validator: (value) => _accountType == 'pumpOwner' && (value == null || value.trim().length < 5) ? 'Enter full station address' : null),
                    ],
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Email address',
                      controller: _email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Mobile number',
                      controller: _phone,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Password (minimum 8 characters)',
                      controller: _password,
                      prefixIcon: Icons.lock_outline,
                      password: true,
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Confirm password',
                      controller: _confirm,
                      prefixIcon: Icons.lock_reset,
                      password: true,
                      validator: (value) {
                        if (value != _password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _accepted,
                      onChanged: (value) {
                        setState(() => _accepted = value ?? false);
                      },
                      title: const Text(
                        'I agree to the terms and privacy policy',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: _accountType == 'pumpOwner' ? 'Submit Owner Application' : 'Create Customer Account',
                      loading: _loading,
                      onPressed: _register,
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
