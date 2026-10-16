import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pulse/app/app.dart';

void main() {
  testWidgets('CNGPulse app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CngPulseApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
