/// Pure calculations for customer-entered refuelling and mileage records.
/// Values are estimates; always validate input before saving a record.
class MileageCalculator {
  MileageCalculator._();

  /// Returns distance / fuel quantity in km per kg.
  static double mileageKmPerKg({required double distanceKm, required double fuelKg}) {
    if (!distanceKm.isFinite || distanceKm < 0) {
      throw ArgumentError.value(distanceKm, 'distanceKm', 'Must be finite and non-negative.');
    }
    if (!fuelKg.isFinite || fuelKg <= 0) {
      throw ArgumentError.value(fuelKg, 'fuelKg', 'Must be finite and greater than zero.');
    }
    return distanceKm / fuelKg;
  }

  /// Returns fuel cost for the supplied quantity and price per kg.
  static double fuelCost({required double fuelKg, required double pricePerKg}) {
    if (!fuelKg.isFinite || fuelKg < 0) {
      throw ArgumentError.value(fuelKg, 'fuelKg', 'Must be finite and non-negative.');
    }
    if (!pricePerKg.isFinite || pricePerKg < 0) {
      throw ArgumentError.value(pricePerKg, 'pricePerKg', 'Must be finite and non-negative.');
    }
    return fuelKg * pricePerKg;
  }

  /// Estimated cost per kilometre, requiring a positive distance.
  static double costPerKm({required double totalCost, required double distanceKm}) {
    if (!totalCost.isFinite || totalCost < 0) {
      throw ArgumentError.value(totalCost, 'totalCost', 'Must be finite and non-negative.');
    }
    if (!distanceKm.isFinite || distanceKm <= 0) {
      throw ArgumentError.value(distanceKm, 'distanceKm', 'Must be finite and greater than zero.');
    }
    return totalCost / distanceKm;
  }
}
