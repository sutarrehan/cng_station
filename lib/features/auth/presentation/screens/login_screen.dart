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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late AnimationController _glowController;

  bool _loading = false;

  // Selected account type:
  // customer or pumpOwner
  String _loginAs = 'customer';

  @override
  void initState() {
    super.initState();

    // Breathing animation for the CNG station logo.
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _glowController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN FUNCTION
  // ============================================================

  Future<void> _login() async {
    if (_loading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final auth = AuthRepository();

      // Authenticate using the existing authentication repository.
      await auth.login(
        _email.text.trim(),
        _password.text,
      );

      final user = auth.currentUser;

      if (user == null) {
        throw Exception('Login failed. User not found.');
      }

      // Retrieve the authenticated user's role.
      final role = await auth.roleFor(user.uid);

      // Determine the expected role.
      final expectedRole =
          _loginAs == 'pumpOwner' ? 'admin' : 'customer';

      // Verify the selected login type.
      if (role != expectedRole) {
        await auth.logout();

        if (!mounted) return;

        final message = _loginAs == 'pumpOwner'
            ? 'This account is not an approved Pump Owner account. '
                'Apply for access or use Customer Login.'
            : 'This account is registered for Pump Owner access. '
                'Please choose Pump Owner Login.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      // Login successful.
      //
      // If your application already has a Firebase authentication
      // listener or route guard, it can navigate to the dashboard.
      //
      // Otherwise, add explicit navigation to your existing
      // Customer Dashboard or Pump Owner Dashboard here.
    } catch (error) {
      if (!mounted) return;

      String message = 'Login failed. Please try again.';

      final errorText = error.toString().toLowerCase();

      if (errorText.contains('invalid-credential') ||
          errorText.contains('wrong-password') ||
          errorText.contains('invalid login credentials')) {
        message = 'Email or password is incorrect.';
      } else if (errorText.contains('user-not-found')) {
        message = 'Account not found.';
      } else if (errorText.contains('network-request-failed') ||
          errorText.contains('socketexception')) {
        message = 'Check your internet connection.';
      } else if (errorText.contains('too-many-requests')) {
        message = 'Too many attempts. Please try again later.';
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
  // NAVIGATION FUNCTIONS
  // ============================================================

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  // ============================================================
  // MAIN LOGIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
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
                    // CNG PULSE BRAND LOGO
                    // ==================================================

                    Center(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(100, 100),
                                painter: LoginStationLogoPainter(
                                  screenGlowOpacity:
                                      _glowController.value,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'CNG PULSE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // WELCOME MESSAGE
                    // ==================================================

                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Choose your account designation to proceed.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // ANIMATED CUSTOMER / PUMP OWNER SELECTOR
                    // ==================================================

                    Container(
                      height: 64,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final segmentWidth =
                              constraints.maxWidth / 2;

                          return Stack(
                            children: [
                              // Sliding white selection background.
                              AnimatedPositioned(
                                duration: const Duration(
                                  milliseconds: 350,
                                ),
                                curve: Curves.easeInOutCubic,
                                left: _loginAs == 'customer'
                                    ? 0
                                    : segmentWidth,
                                top: 0,
                                bottom: 0,
                                width: segmentWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Both selectable options.
                              Row(
                                children: [
                                  Expanded(
                                    child: _AnimatedLoginOption(
                                      title: 'Customer',
                                      icon: Icons.person_outline_rounded,
                                      selected:
                                          _loginAs == 'customer',
                                      onTap: () {
                                        if (_loading) return;

                                        setState(() {
                                          _loginAs = 'customer';
                                        });
                                      },
                                    ),
                                  ),

                                  Expanded(
                                    child: _AnimatedLoginOption(
                                      title: 'Pump Owner',
                                      icon:
                                          Icons.local_gas_station_rounded,
                                      selected:
                                          _loginAs == 'pumpOwner',
                                      onTap: () {
                                        if (_loading) return;

                                        setState(() {
                                          _loginAs = 'pumpOwner';
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
                    // EMAIL FIELD
                    // ==================================================

                    CustomTextField(
                      label: 'Email address',
                      controller: _email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your email address';
                        }

                        final emailRegex = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // PASSWORD FIELD
                    // ==================================================

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

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : _openForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF2563EB),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    PrimaryButton(
                      label: _loginAs == 'pumpOwner'
                          ? 'Login as Pump Owner'
                          : 'Login as Customer',
                      loading: _loading,
                      onPressed: _login,
                      icon: Icons.login_rounded,
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // REGISTRATION
                    // ==================================================

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),

                          TextButton(
                            onPressed: _loading
                                ? null
                                : _openRegister,
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF059669),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // FOOTER
                    // ==================================================

                    const Center(
                      child: Text(
                        '⚡ Smarter stops. Shorter waits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
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

// ================================================================
// ANIMATED CUSTOMER / PUMP OWNER OPTION
// ================================================================

class _AnimatedLoginOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AnimatedLoginOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF059669);
    const unselectedColor = Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.expand(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon scale and color.
              AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey('$icon-$selected'),
                    size: 22,
                    color: selected
                        ? selectedColor
                        : unselectedColor,
                  ),
                ),
              ),

              const SizedBox(width: 9),

              // Animated text style.
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
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
// CUSTOM ANIMATED CNG FUEL DISPENSER LOGO
// ================================================================

class LoginStationLogoPainter extends CustomPainter {
  final double screenGlowOpacity;

  LoginStationLogoPainter({
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

    // ============================================================
    // 1. MAIN FUEL DISPENSER BODY
    // ============================================================

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

    // ============================================================
    // 2. BASE PLATE
    // ============================================================

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

    // ============================================================
    // 3. DISPLAY SCREEN AND GLOW
    // ============================================================

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

    // Breathing neon border.
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

    // CNG text inside the display.
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'CNG',
        style: TextStyle(
          color: baseGreen,
          fontSize: 13,
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

    // ============================================================
    // 4. FUEL HOSE
    // ============================================================

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
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // ============================================================
    // 5. FUEL NOZZLE
    // ============================================================

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

    // White grip cutout.
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
    covariant LoginStationLogoPainter oldDelegate,
  ) {
    return oldDelegate.screenGlowOpacity != screenGlowOpacity;
  }
}