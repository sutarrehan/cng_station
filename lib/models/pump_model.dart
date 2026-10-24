class PumpModel {
  final String id, name, address, ownerId;
  final bool active;
  final double? pricePerKg;
  const PumpModel({required this.id, this.name = '', this.address = '', this.ownerId = '', this.active = true, this.pricePerKg});
  factory PumpModel.fromMap(String id, Map<String, dynamic> m) => PumpModel(id: id, name: '${m['name'] ?? ''}', address: '${m['address'] ?? ''}', ownerId: '${m['ownerId'] ?? ''}', active: m['active'] is bool ? m['active'] as bool : true, pricePerKg: (m['pricePerKg'] as num?)?.toDouble());
  Map<String, dynamic> toMap() => {'name': name, 'address': address, 'ownerId': ownerId, 'active': active, if (pricePerKg != null) 'pricePerKg': pricePerKg};
}
