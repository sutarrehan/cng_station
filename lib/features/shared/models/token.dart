class CngToken {
  final String id, customerId, stationId, status;
  final int? tokenNumber, position;
  const CngToken(
      {required this.id,
      required this.customerId,
      required this.stationId,
      required this.status,
      this.tokenNumber,
      this.position});
  factory CngToken.fromMap(String id, Map<String, dynamic> d) => CngToken(
      id: id,
      customerId: d['customerId']?.toString() ?? '',
      stationId: d['stationId']?.toString() ?? '',
      status: d['status']?.toString() ?? 'pending',
      tokenNumber: (d['tokenNumber'] as num?)?.toInt(),
      position: (d['position'] as num?)?.toInt());
}
