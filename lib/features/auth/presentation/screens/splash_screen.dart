import 'package:flutter/material.dart';

/// Lightweight branded splash. Authentication and role routing are handled by AuthGate.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_gas_station_rounded, size: 72, color: Color(0xFF07865C)),
        SizedBox(height: 16),
        Text('CNGPulse', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Smart CNG Station Management'),
        SizedBox(height: 24),
        CircularProgressIndicator(),
      ],
    )),
  );
}
