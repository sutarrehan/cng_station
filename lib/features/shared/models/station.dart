class Station {
  final String id, name, address, availability;
  final double? pricePerKg;
  final int queueCount;
  const Station(
      {required this.id,
      required this.name,
      required this.address,
      required this.availability,
      this.pricePerKg,
      this.queueCount = 0});
  factory Station.fromMap(String id, Map<String, dynamic> data) => Station(
      id: id,
      name: data['name']?.toString() ?? 'CNG Station',
      address: data['address']?.toString() ?? '',
      availability: data['availability']?.toString() ?? 'unknown',
      pricePerKg: (data['pricePerKg'] as num?)?.toDouble(),
      queueCount: (data['queueCount'] as num?)?.toInt() ?? 0);
  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'availability': availability,
        'pricePerKg': pricePerKg,
        'queueCount': queueCount
      };
}
