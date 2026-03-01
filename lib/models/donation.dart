/// Model representing a donation record stored in the local database.
class Donation {
  final int? id;
  final String campaign;
  final double amount;
  final double tip;
  final double total;
  final String paymentMethod;
  final String transactionId;
  final String note;
  final String date; // ISO 8601

  const Donation({
    this.id,
    required this.campaign,
    required this.amount,
    required this.tip,
    required this.total,
    required this.paymentMethod,
    required this.transactionId,
    this.note = '',
    required this.date,
  });

  /// Convert to a map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'campaign': campaign,
      'amount': amount,
      'tip': tip,
      'total': total,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'note': note,
      'date': date,
    };
  }

  /// Create a Donation from a database row.
  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id'] as int?,
      campaign: map['campaign'] as String,
      amount: (map['amount'] as num).toDouble(),
      tip: (map['tip'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      transactionId: map['transactionId'] as String,
      note: (map['note'] as String?) ?? '',
      date: map['date'] as String,
    );
  }

  /// Create a copy with updated fields.
  Donation copyWith({
    int? id,
    String? campaign,
    double? amount,
    double? tip,
    double? total,
    String? paymentMethod,
    String? transactionId,
    String? note,
    String? date,
  }) {
    return Donation(
      id: id ?? this.id,
      campaign: campaign ?? this.campaign,
      amount: amount ?? this.amount,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  /// Friendly formatted date (e.g. "28 Jan 2025").
  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date;
    }
  }
}
