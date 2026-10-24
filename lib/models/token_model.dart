class TokenModel {
  final String id, customerId, stationId, status;
  final int tokenNumber, queuePosition;
  final String? stationOwnerId;
  const TokenModel({required this.id, required this.customerId, required this.stationId, required this.tokenNumber, required this.queuePosition, this.status = 'waiting', this.stationOwnerId});
  factory TokenModel.fromMap(String id, Map<String, dynamic> m) => TokenModel(id: id, customerId: '${m['customerId'] ?? ''}', stationId: '${m['stationId'] ?? ''}', tokenNumber: (m['tokenNumber'] as num?)?.toInt() ?? 0, queuePosition: (m['queuePosition'] as num?)?.toInt() ?? 0, status: '${m['status'] ?? 'waiting'}', stationOwnerId: m['stationOwnerId']?.toString());
  Map<String, dynamic> toMap() => {'customerId': customerId, 'stationId': stationId, 'tokenNumber': tokenNumber, 'queuePosition': queuePosition, 'status': status, if (stationOwnerId != null) 'stationOwnerId': stationOwnerId};
}
