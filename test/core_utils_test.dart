import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pulse/core/utils/mileage_calculator.dart';
import 'package:cng_pulse/core/utils/validators.dart';

void main() {
  group('MileageCalculator', () {
    test('calculates mileage', () {
      expect(MileageCalculator.mileageKmPerKg(distanceKm: 120, fuelKg: 4), 30);
    });
    test('calculates fuel cost', () {
      expect(MileageCalculator.fuelCost(fuelKg: 5, pricePerKg: 90), 450);
    });
    test('rejects zero fuel quantity for mileage', () {
      expect(() => MileageCalculator.mileageKmPerKg(distanceKm: 100, fuelKg: 0), throwsArgumentError);
    });
  });
  group('AppValidators', () {
    test('accepts valid email', () => expect(AppValidators.email('person@example.com'), isNull));
    test('rejects invalid email', () => expect(AppValidators.email('not-an-email'), isNotNull));
    test('validates password length', () => expect(AppValidators.password('short'), isNotNull));
    test('accepts a 10 digit phone', () => expect(AppValidators.phone('9876543210'), isNull));
  });
}
