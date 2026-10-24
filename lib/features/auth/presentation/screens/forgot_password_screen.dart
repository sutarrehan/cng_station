import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Form validation key.
  final GlobalKey<FormState> _formSecureKey = GlobalKey<FormState>();

  final _email = TextEditingController();

  bool _loading = false;

  // 0 = Email Link, 1 = Mobile OTP.
  int _selectedMethodIndex = 0;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// Sanitizes the input by removing HTML tags and javascript: strings.
  String _sanitizeInputString(String rawInput) {
    final String trimmed = rawInput.trim();

    final RegExp tagsExpression = RegExp(
      r'<[^>]*>|javascript:',
      caseSensitive: false,
    );

    return trimmed.replaceAll(tagsExpression, '');
  }

  // ============================================================
  // SEND PASSWORD RESET LINK OR MOBILE OTP
  // ============================================================

  Future<void> _send() async {
    if (_loading) return;

    if (_formSecureKey.currentState == null ||
        !_formSecureKey.currentState!.validate()) {
      return;
    }

    final String sanitizedPayload =
        _sanitizeInputString(_email.text);

    if (_selectedMethodIndex == 1) {
      // SMS OTP simulation.
      // A real OTP requires an SMS/phone authentication provider.
      setState(() => _loading = true);

      try {
        await Future.delayed(
          const Duration(milliseconds: 1400),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS OTP is not connected yet. Configure a phone authentication provider.',
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to process the mobile verification request.',
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }

      return;
    }

    // Email password reset.
    setState(() => _loading = true);

    try {
      await AuthRepository().resetPassword(sanitizedPayload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If this email is registered, a reset link has been sent.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send reset email. Check the address and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FCF5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF141E1A),
        ),
        title: const Text(
          'Reset password',
          style: TextStyle(
            color: Color(0xFF141E1A),
          ),
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),

                child: Form(
                  key: _formSecureKey,
                  autovalidateMode:
                      AutovalidateMode.onUserInteraction,

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      // ==========================================
                      // BRANDING ICON
                      // ==========================================

                      Container(
                        height: 96,
                        width: 96,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF141E1A)
                                  .withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.shield_outlined,
                          size: 44,
                          color: Color(0xFF006446),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ==========================================
                      // TITLE
                      // ==========================================

                      const Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF141E1A),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Select your preferred recovery method to '
                        'verify your account and reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3E4943),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ==========================================
                      // RECOVERY METHOD CARDS
                      // ==========================================

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInteractiveMethodCard(
                              index: 0,
                              icon: Icons.alternate_email_rounded,
                              title: 'Email Link',
                              subtitle:
                                  'Reset your password using email.',
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: _buildInteractiveMethodCard(
                              index: 1,
                              icon: Icons.sms_outlined,
                              title: 'Mobile OTP',
                              subtitle:
                                  'Verify your registered phone number.',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ==========================================
                      // DYNAMIC INPUT FIELD
                      // ==========================================

                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 250,
                        ),

                        child: _selectedMethodIndex == 0
                            ? CustomTextField(
                                key: const ValueKey(
                                  'email_field_secure',
                                ),
                                label: 'Email address',
                                controller: _email,
                                prefixIcon: Icons.email_outlined,
                                keyboardType:
                                    TextInputType.emailAddress,

                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Email address is required.';
                                  }

                                  final String sanitized =
                                      _sanitizeInputString(value);

                                  final RegExp emailPattern =
                                      RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );

                                  if (!emailPattern
                                      .hasMatch(sanitized)) {
                                    return 'Enter a valid email address.';
                                  }

                                  return null;
                                },
                              )
                            : CustomTextField(
                                key: const ValueKey(
                                  'sms_field_secure',
                                ),
                                label: 'Registered phone number',
                                controller: _email,
                                prefixIcon:
                                    Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,

                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Registered mobile number is required.';
                                  }

                                  final String sanitized =
                                      _sanitizeInputString(value);

                                  final RegExp digitsPattern =
                                      RegExp(r'^[0-9]{10,14}$');

                                  if (!digitsPattern
                                      .hasMatch(sanitized)) {
                                    return 'Enter a valid phone number (10–14 digits).';
                                  }

                                  return null;
                                },
                              ),
                      ),

                      const SizedBox(height: 32),

                      // ==========================================
                      // SUBMIT BUTTON
                      // ==========================================

                      PrimaryButton(
                        label: _selectedMethodIndex == 0
                            ? 'Send reset link'
                            : 'Generate SMS code',
                        loading: _loading,
                        onPressed: _send,
                      ),

                      const SizedBox(height: 24),

                      // ==========================================
                      // BACK TO LOGIN
                      // ==========================================

                      TextButton.icon(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                        ),
                        label: const Text('Back to Login'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF006446),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // INTERACTIVE RECOVERY METHOD CARD
  // ============================================================

  Widget _buildInteractiveMethodCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected =
        _selectedMethodIndex == index;

    return InkWell(
      onTap: _loading
          ? null
          : () {
              setState(() {
                _selectedMethodIndex = index;

                // Clear the previous method's input.
                _email.clear();

                // Reset previous validation messages.
                _formSecureKey.currentState?.reset();
              });
            },

      borderRadius: BorderRadius.circular(16),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: isSelected
                ? const Color(0xFF006446)
                : Colors.transparent,
            width: 2,
          ),

          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF006446).withOpacity(0.08)
                  : const Color(0xFF141E1A).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF006446)
                  : const Color(0xFF3E4943),
              size: 28,
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF006446)
                    : const Color(0xFF141E1A),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF3E4943),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // Selected indicator.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: isSelected ? 36 : 12,

              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF006446)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}