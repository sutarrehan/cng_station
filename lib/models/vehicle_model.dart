class VehicleModel {
  final String id, customerId, registrationNumber, make, model, fuelType;
  final bool isPrimary;
  const VehicleModel({required this.id, required this.customerId, this.registrationNumber = '', this.make = '', this.model = '', this.fuelType = 'CNG', this.isPrimary = false});
  factory VehicleModel.fromMap(String id, Map<String, dynamic> m) => VehicleModel(id: id, customerId: '${m['customerId'] ?? ''}', registrationNumber: '${m['registrationNumber'] ?? m['registrationNo'] ?? ''}', make: '${m['make'] ?? ''}', model: '${m['model'] ?? ''}', fuelType: '${m['fuelType'] ?? 'CNG'}', isPrimary: m['isPrimary'] == true);
  Map<String, dynamic> toMap() => {'customerId': customerId, 'registrationNumber': registrationNumber, 'make': make, 'model': model, 'fuelType': fuelType, 'isPrimary': isPrimary};
}
