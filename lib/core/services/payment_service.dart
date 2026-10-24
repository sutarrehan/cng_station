/// Razorpay integration boundary.
/// Checkout can be started only after a trusted backend creates an order.
/// The payment signature must be verified on a trusted server, never in Flutter.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  Future<void> startCheckout({
    required String orderId,
    required int amountPaise,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    if (orderId.trim().isEmpty || amountPaise <= 0) {
      throw ArgumentError('A valid server-created order and amount are required.');
    }
    throw UnsupportedError(
      'Razorpay checkout is gated until the Razorpay key and trusted order/signature-verification backend are configured.',
    );
  }
}
