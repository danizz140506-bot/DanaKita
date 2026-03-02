/// Model representing a saved payment method with credentials.
class PaymentMethod {
  final int? id;
  final String type;       // 'Card', 'FPX', 'E-Wallet'
  final String provider;   // 'Maybank', 'Visa', 'ShopeePay', etc.
  final String label;      // Display name: 'Visa ****4242'
  final String credential; // Masked credential: '****4242'

  const PaymentMethod({
    this.id,
    required this.type,
    required this.provider,
    required this.label,
    this.credential = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'provider': provider,
      'label': label,
      'credential': credential,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int?,
      type: map['type'] as String,
      provider: (map['provider'] as String?) ?? '',
      label: map['label'] as String,
      credential: (map['credential'] as String?) ?? '',
    );
  }

  PaymentMethod copyWith({
    int? id,
    String? type,
    String? provider,
    String? label,
    String? credential,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      label: label ?? this.label,
      credential: credential ?? this.credential,
    );
  }

  /// Asset path for the provider logo.
  String get logoPath {
    switch (provider) {
      case 'Maybank':
        return 'assets/images/payments/maybank.webp';
      case 'Visa':
        return 'assets/images/payments/visa.webp';
      case 'Touch \'n Go':
        return 'assets/images/payments/tng.webp';
      case 'Mastercard':
        return 'assets/images/payments/mastercard.webp';
      case 'CIMB':
        return 'assets/images/payments/cimb.webp';
      case 'GrabPay':
        return 'assets/images/payments/grab.webp';
      default:
        return '';
    }
  }
}

// ── Provider registry (all available providers per type) ─────────────────────

class PaymentProvider {
  final String name;
  final String type; // 'Card', 'FPX', 'E-Wallet'
  final String logoAsset;
  const PaymentProvider(this.name, this.type, this.logoAsset);
}

const allProviders = [
  // FPX
  PaymentProvider('Maybank', 'FPX', 'assets/images/payments/maybank.webp'),
  PaymentProvider('CIMB', 'FPX', 'assets/images/payments/cimb.webp'),
  // Card
  PaymentProvider('Visa', 'Card', 'assets/images/payments/visa.webp'),
  PaymentProvider('Mastercard', 'Card', 'assets/images/payments/mastercard.webp'),
  // E-Wallet
  PaymentProvider('Touch \'n Go', 'E-Wallet', 'assets/images/payments/tng.webp'),
  PaymentProvider('GrabPay', 'E-Wallet', 'assets/images/payments/grab.webp'),
];

List<PaymentProvider> providersForType(String type) =>
    allProviders.where((p) => p.type == type).toList();

/// Mask a credential string, showing only the last 4 characters.
String maskCredential(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[\s\-/]'), '');
  if (cleaned.length <= 4) return cleaned;
  return '****${cleaned.substring(cleaned.length - 4)}';
}
