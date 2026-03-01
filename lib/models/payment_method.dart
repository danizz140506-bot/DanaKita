import 'package:flutter/material.dart';

/// Model representing a saved payment method.
class PaymentMethod {
  final int? id;
  final String type; // 'Card', 'e-Wallet', 'Bank Transfer'
  final String label; // e.g. 'Visa ending in 4242'

  const PaymentMethod({
    this.id,
    required this.type,
    required this.label,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'label': label,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int?,
      type: map['type'] as String,
      label: map['label'] as String,
    );
  }

  PaymentMethod copyWith({int? id, String? type, String? label}) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
    );
  }

  IconData get icon {
    switch (type) {
      case 'Card':
        return Icons.credit_card;
      case 'e-Wallet':
        return Icons.account_balance_wallet_rounded;
      case 'Bank Transfer':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}
