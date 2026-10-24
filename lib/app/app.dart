import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_router.dart';
import '../features/auth/presentation/screens/auth_gate.dart';

class CngPulseApp extends StatelessWidget {
  const CngPulseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CNGPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      );
}
