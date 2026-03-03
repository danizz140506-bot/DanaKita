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
      status: json['status'] ?? 'success',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert this result back to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': transactionId,
      'amount': amount,
      'campaign': campaign,
      'paymentMethod': paymentMethod,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  PaymentResult copyWith({
    int? transactionId,
    double? amount,
    String? campaign,
    String? paymentMethod,
    String? status,
    DateTime? timestamp,
  }) {
    return PaymentResult(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      campaign: campaign ?? this.campaign,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Formatted transaction ID (e.g. "TXN-00101").
  String get formattedId => 'TXN-${transactionId.toString().padLeft(5, '0')}';
}

