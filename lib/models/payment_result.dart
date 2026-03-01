/// Model representing a payment response from the mock payment API.
class PaymentResult {
  final int transactionId;
  final double amount;
  final String campaign;
  final String paymentMethod;
  final String status;
  final DateTime timestamp;

  const PaymentResult({
    required this.transactionId,
    required this.amount,
    required this.campaign,
    required this.paymentMethod,
    required this.status,
    required this.timestamp,
  });

  /// Parse the response from the mock payment API.
  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      transactionId: json['id'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      campaign: json['campaign'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: 'success',
      timestamp: DateTime.now(),
    );
  }

  /// Formatted transaction ID (e.g. "TXN-00101").
  String get formattedId => 'TXN-${transactionId.toString().padLeft(5, '0')}';
}
