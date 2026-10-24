import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    home: CngPulseSplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class CngPulseSplashScreen extends StatefulWidget {
  const CngPulseSplashScreen({super.key});

  @override
  State<CngPulseSplashScreen> createState() => _CngPulseSplashScreenState();
}

class _CngPulseSplashScreenState extends State<CngPulseSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _fillAnimation;
  late Animation<double> _nozzleLiftAnimation;
  late Animation<double> _screenPulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controls the full fueling animation timeline (4 seconds total duration)
    _loadingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Dynamic fuel percentage value mapping
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.fastOutSlowIn),
    );

    // 2. Interactive Nozzle Movement: Nozzle lifts up smoothly at the start of loading
    _nozzleLiftAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -12.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: -8.0), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // 3. Screen Neon Pulse: Causes the display screen inside the green pump to glow/breathe
    _screenPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.3), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.2, 0.9, curve: Curves.linear),
      ),
    );

    _loadingController.addListener(() {
      setState(() {});
    });

    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    // Start filling sequence
    await _loadingController.forward();

    if (!mounted) return;

    // Transition smoothly straight into your authentic Login/Signin framework
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CngPulseApp()),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 24, 21, 21), // Pure clean white background canvas
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom Paint vector engine mapping your provided station silhouette
            CustomPaint(
              size: const Size(160, 160), // Perfectly scaled medium vector dimensions
              painter: CngStationLogoPainter(
                progress: _fillAnimation.value,
                nozzleOffset: _nozzleLiftAnimation.value,
                screenGlowOpacity: _screenPulseAnimation.value,
              ),
            ),
            const SizedBox(height: 35),
            
            // Fixed App branding text positioned safely inside the loading screen layout
            const Text(
              "CNG PULSE",
              style: TextStyle(
                color: Color(0xFF1E3A8A), // Clean Premium Dark Navy
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 8),
            
            // Fueling digital counter matching the green theme
            Text(
              "Fueling... ${(_fillAnimation.value * 100).toInt()}%",
              style: TextStyle(
                color: const Color(0xFF10B981), // Premium Vibrant Green
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A precise canvas renderer mapping the silhouette shape structures of the
/// provided reference image, utilizing dynamic multi-stage progressive green fills.
class CngStationLogoPainter extends CustomPainter {
  final double progress;
  final double nozzleOffset;
  final double screenGlowOpacity;

  CngStationLogoPainter({
    required this.progress,
    required this.nozzleOffset,
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

    final shellOutlinePaint = Paint()
      ..color = baseGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // --- 1. Draw Main Pump Station Mainframe Body ---
    final mainBodyRect = Rect.fromLTWH(size.width * 0.40, size.height * 0.15, size.width * 0.50, size.height * 0.70);
    final mainBodyRRect = RRect.fromRectAndRadius(mainBodyRect, const Radius.circular(12));
    
    // Draw the baseline unfilled container structure background shell outline
    canvas.drawRRect(mainBodyRRect, shellOutlinePaint);

    // Masked dynamic green liquid fill from bottom to top
    canvas.save();
    final fillHeight = mainBodyRect.height * progress;
    final fillRect = Rect.fromLTWH(mainBodyRect.left, mainBodyRect.bottom - fillHeight, mainBodyRect.width, fillHeight);
    canvas.clipRRect(mainBodyRRect);
    canvas.drawRect(fillRect, baseStationPaint);
    canvas.restore();

    // --- 2. Draw Bottom Pedestal Base Plate Accent ---
    final basePlateRect = Rect.fromLTWH(size.width * 0.36, size.height * 0.85, size.width * 0.58, size.height * 0.05);
    canvas.drawRect(basePlateRect, baseStationPaint);

    // --- 3. Draw Central Text & Display Window Panel ---
    final displayRect = Rect.fromLTWH(size.width * 0.47, size.height * 0.22, size.width * 0.36, size.height * 0.20);
    final displayRRect = RRect.fromRectAndRadius(displayRect, const Radius.circular(6));
    
    final displayBoxPaint = Paint()
      ..color = lightGreen.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(displayRRect, displayBoxPaint);

    // Glowing Neon interactive display aura border
    final glowPaint = Paint()
      ..color = vibrantGreen.withValues(alpha: screenGlowOpacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(displayRRect, glowPaint);

    // Render internal core "CNG" identifier label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'CNG',
        style: TextStyle(
          color: baseGreen,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas, 
      Offset(
        displayRect.left + (displayRect.width - textPainter.width) / 2,
        displayRect.top + (displayRect.height - textPainter.height) / 2,
      ),
    );

    // --- 4. Draw Flexible Hose Line ---
    final hosePath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.58)
      ..cubicTo(
        size.width * 0.30, size.height * 0.60,
        size.width * 0.25, size.height * 0.80,
        size.width * 0.30, size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.35, size.height * 0.87,
        size.width * 0.35, size.height * 0.55,
        size.width * 0.22, size.height * 0.52,
      );

    final hosePaint = Paint()
      ..color = baseGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hosePath, hosePaint);

    // --- 5. Draw Fuel Dispenser Nozzle Gun ---
    canvas.save();
    canvas.translate(0, nozzleOffset); // Smoothly lifts up during loading phase

    final nozzlePath = Path()
      ..moveTo(size.width * 0.20, size.height * 0.52)
      ..lineTo(size.width * 0.20, size.height * 0.34)
      ..lineTo(size.width * 0.28, size.height * 0.28)
      ..lineTo(size.width * 0.34, size.height * 0.22)
      ..lineTo(size.width * 0.36, size.height * 0.24)
      ..lineTo(size.width * 0.30, size.height * 0.32)
      ..lineTo(size.width * 0.30, size.height * 0.52)
      ..close();

    canvas.drawPath(nozzlePath, baseStationPaint);

    // Internal clean cutout grip line window details matching reference logo blueprint
    final gripCutoutPath = Path()
      ..moveTo(size.width * 0.24, size.height * 0.38)
      ..lineTo(size.width * 0.27, size.height * 0.35)
      ..lineTo(size.width * 0.27, size.height * 0.46)
      ..lineTo(size.width * 0.24, size.height * 0.46)
      ..close();

    final cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(gripCutoutPath, cutoutPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CngStationLogoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.nozzleOffset != nozzleOffset ||
        oldDelegate.screenGlowOpacity != screenGlowOpacity;
  }
}
