class TransactionModel {
  final String id, customerId, stationId;
  final double fuelKg, pricePerKg, distanceKm;
  final DateTime? createdAt;
  const TransactionModel({required this.id, required this.customerId, required this.stationId, this.fuelKg = 0, this.pricePerKg = 0, this.distanceKm = 0, this.createdAt});
  double get totalCost => fuelKg * pricePerKg;
  double? get mileageKmPerKg => fuelKg > 0 && distanceKm >= 0 ? distanceKm / fuelKg : null;
  Map<String, dynamic> toMap() => {'customerId': customerId, 'stationId': stationId, 'fuelKg': fuelKg, 'pricePerKg': pricePerKg, 'distanceKm': distanceKm, 'totalCost': totalCost, if (createdAt != null) 'createdAt': createdAt};
}
