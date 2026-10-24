import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _stationNameController = TextEditingController();

  late AnimationController _glowController;

  String _selectedRole = 'customer';

  bool _loading = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _stationNameController.dispose();
    _glowController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER ACCOUNT
  // ============================================================

  Future<void> _registerAccount() async {
    if (_loading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the terms and privacy policy to continue.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final auth = AuthRepository();

      // The existing AuthRepository requires name and phone.
      // Use its supported parameters to avoid named-parameter errors.
      await auth.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _fullNameController.text.trim(),
        phone: _mobileController.text.trim(),
      );

      if (!mounted) return;

      String successMessage = 'Account created successfully!';

      if (_selectedRole == 'pumpOwner') {
        successMessage =
            'Account created successfully! '
            'Pump Owner access requires administrator approval.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      String message = 'Registration failed. Please try again.';

      final errorText = error.toString().toLowerCase();

      if (errorText.contains('email-already-in-use')) {
        message = 'This email address is already registered.';
      } else if (errorText.contains('invalid-email')) {
        message = 'Please enter a valid email address.';
      } else if (errorText.contains('weak-password')) {
        message = 'Please choose a stronger password.';
      } else if (errorText.contains('network-request-failed') ||
          errorText.contains('socketexception')) {
        message = 'Check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 16,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // ANIMATED CNG LOGO
                    // ==================================================

                    Center(
                      child: AnimatedBuilder(
                        animation: _glowController,

                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(80, 80),

                            painter: RegisterStationLogoPainter(
                              screenGlowOpacity:
                                  _glowController.value,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // HEADER
                    // ==================================================

                    const Text(
                      'Join CNGPulse',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Create your role-based access identity to proceed.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // ROLE SELECTION
                    // ==================================================

                    Container(
                      height: 58,
                      padding: const EdgeInsets.all(4),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final segmentWidth =
                              constraints.maxWidth / 2;

                          return Stack(
                            children: [
                              // Animated selection background.
                              AnimatedPositioned(
                                duration:
                                    const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                left: _selectedRole == 'customer'
                                    ? 0
                                    : segmentWidth,
                                top: 0,
                                bottom: 0,
                                width: segmentWidth,

                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(11),

                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child: _RegisterRoleTab(
                                      title: 'Customer',
                                      icon:
                                          Icons.person_outline_rounded,
                                      isSelected:
                                          _selectedRole == 'customer',

                                      onTap: () {
                                        if (_loading) return;

                                        setState(() {
                                          _selectedRole = 'customer';
                                        });
                                      },
                                    ),
                                  ),

                                  Expanded(
                                    child: _RegisterRoleTab(
                                      title: 'Pump Owner',
                                      icon: Icons
                                          .local_gas_station_rounded,
                                      isSelected:
                                          _selectedRole == 'pumpOwner',

                                      onTap: () {
                                        if (_loading) return;

                                        setState(() {
                                          _selectedRole = 'pumpOwner';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // FULL NAME
                    // ==================================================

                    CustomTextField(
                      label: 'Full name',
                      controller: _fullNameController,
                      prefixIcon: Icons.person_outline,

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your full name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    CustomTextField(
                      label: 'Email address',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,

                      validator: (value) {
                        if (value == null ||
                            !RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // MOBILE NUMBER
                    // ==================================================

                    CustomTextField(
                      label: 'Mobile number',
                      controller: _mobileController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,

                      validator: (value) {
                        if (value == null ||
                            value.trim().length < 10) {
                          return 'Enter a valid mobile number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // PUMP OWNER STATION NAME
                    // ==================================================

                    if (_selectedRole == 'pumpOwner') ...[
                      CustomTextField(
                        label: 'Station Identification Name',
                        controller: _stationNameController,
                        prefixIcon: Icons.storefront_outlined,

                        validator: (value) {
                          if (_selectedRole == 'pumpOwner' &&
                              (value == null ||
                                  value.trim().isEmpty)) {
                            return 'Enter your station name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                    ],

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    CustomTextField(
                      label: 'Password (minimum 8 characters)',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      password: true,

                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters long';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // CONFIRM PASSWORD
                    // ==================================================

                    CustomTextField(
                      label: 'Confirm password',
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_reset_outlined,
                      password: true,

                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // TERMS AND CONDITIONS
                    // ==================================================

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,

                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: const Color(0xFF059669),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),

                            onChanged: _loading
                                ? null
                                : (value) {
                                    setState(() {
                                      _agreeToTerms = value ?? false;
                                    });
                                  },
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Text(
                            'I agree to the operational user terms, '
                            'service metrics, and systemic privacy '
                            'conditions policy.',

                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // CREATE ACCOUNT BUTTON
                    // ==================================================

                    PrimaryButton(
                      label: 'Create Account',
                      loading: _loading,
                      onPressed: _registerAccount,
                      icon: Icons.person_add_alt_1_rounded,
                    ),

                    const SizedBox(height: 20),
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

// ================================================================
// ANIMATED ROLE TAB
// ================================================================

class _RegisterRoleTab extends StatelessWidget {
  final bool isSelected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RegisterRoleTab({
    required this.isSelected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),

        child: SizedBox.expand(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 250),

                child: Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? const Color(0xFF059669)
                      : Colors.grey.shade500,
                ),
              ),

              const SizedBox(width: 6),

              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade500,
                  ),

                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CUSTOM REGISTER STATION LOGO
// ================================================================

class RegisterStationLogoPainter extends CustomPainter {
  final double screenGlowOpacity;

  RegisterStationLogoPainter({
    required this.screenGlowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const baseGreen = Color(0xFF059669);
    const lightGreen = Color(0xFFD1FAE5);
    const vibrantGreen = Color(0xFF10B981);

    final baseStationPaint = Paint()
      ..color = baseGreen
      ..style = PaintingStyle.fill;

    // Main fuel dispenser body.
    final mainBodyRect = Rect.fromLTWH(
      size.width * 0.40,
      size.height * 0.15,
      size.width * 0.50,
      size.height * 0.70,
    );

    final mainBodyRRect = RRect.fromRectAndRadius(
      mainBodyRect,
      const Radius.circular(10),
    );

    canvas.drawRRect(
      mainBodyRRect,
      baseStationPaint,
    );

    // Base plate.
    final basePlateRect = Rect.fromLTWH(
      size.width * 0.36,
      size.height * 0.85,
      size.width * 0.58,
      size.height * 0.05,
    );

    canvas.drawRect(
      basePlateRect,
      baseStationPaint,
    );

    // Display screen.
    final displayRect = Rect.fromLTWH(
      size.width * 0.47,
      size.height * 0.22,
      size.width * 0.36,
      size.height * 0.20,
    );

    final displayRRect = RRect.fromRectAndRadius(
      displayRect,
      const Radius.circular(5),
    );

    canvas.drawRRect(
      displayRRect,
      Paint()..color = lightGreen,
    );

    // Animated screen glow.
    final glowPaint = Paint()
      ..color = vibrantGreen.withValues(
        alpha: screenGlowOpacity * 0.7,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      displayRRect,
      glowPaint,
    );

    // CNG display text.
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'CNG',
        style: TextStyle(
          color: baseGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        displayRect.left +
            (displayRect.width - textPainter.width) / 2,
        displayRect.top +
            (displayRect.height - textPainter.height) / 2,
      ),
    );

    // Fuel hose.
    final hosePath = Path()
      ..moveTo(
        size.width * 0.40,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.60,
        size.width * 0.25,
        size.height * 0.80,
        size.width * 0.30,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.87,
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.22,
        size.height * 0.52,
      );

    canvas.drawPath(
      hosePath,
      Paint()
        ..color = baseGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Fuel nozzle.
    final nozzlePath = Path()
      ..moveTo(
        size.width * 0.20,
        size.height * 0.52,
      )
      ..lineTo(
        size.width * 0.20,
        size.height * 0.34,
      )
      ..lineTo(
        size.width * 0.28,
        size.height * 0.28,
      )
      ..lineTo(
        size.width * 0.34,
        size.height * 0.22,
      )
      ..lineTo(
        size.width * 0.36,
        size.height * 0.24,
      )
      ..lineTo(
        size.width * 0.30,
        size.height * 0.32,
      )
      ..lineTo(
        size.width * 0.30,
        size.height * 0.52,
      )
      ..close();

    canvas.drawPath(
      nozzlePath,
      baseStationPaint,
    );

    // White nozzle grip.
    final gripCutoutPath = Path()
      ..moveTo(
        size.width * 0.24,
        size.height * 0.38,
      )
      ..lineTo(
        size.width * 0.27,
        size.height * 0.35,
      )
      ..lineTo(
        size.width * 0.27,
        size.height * 0.46,
      )
      ..lineTo(
        size.width * 0.24,
        size.height * 0.46,
      )
      ..close();

    canvas.drawPath(
      gripCutoutPath,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(
    covariant RegisterStationLogoPainter oldDelegate,
  ) {
    return oldDelegate.screenGlowOpacity != screenGlowOpacity;
  }
}