/// Payment record model only. Do not mark a payment successful from the client;
/// status must be verified by a trusted payment provider/backend.
class PaymentModel {
  final String id, customerId, bookingId, status, currency;
  final int amountPaise;
  const PaymentModel({required this.id, required this.customerId, required this.bookingId, required this.amountPaise, this.status = 'pending', this.currency = 'INR'});
  factory PaymentModel.fromMap(String id, Map<String, dynamic> m) => PaymentModel(id: id, customerId: '${m['customerId'] ?? ''}', bookingId: '${m['bookingId'] ?? ''}', amountPaise: (m['amountPaise'] as num?)?.toInt() ?? 0, status: '${m['status'] ?? 'pending'}', currency: '${m['currency'] ?? 'INR'}');
  Map<String, dynamic> toMap() => {'customerId': customerId, 'bookingId': bookingId, 'amountPaise': amountPaise, 'status': status, 'currency': currency};
}
