import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/fade_in_widget.dart';

/// Dummy payment method for UI mockup (no backend).
class _PaymentMethod {
  final String label;
  final String? subtitle; // e.g. "•••• 4242"
  final IconData icon;
  final bool isDefault;

  const _PaymentMethod({
    required this.label,
    this.subtitle,
    required this.icon,
    this.isDefault = false,
  });
}

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  static const _methods = [
    _PaymentMethod(
      label: 'Visa •••• 4242',
      subtitle: 'Expires 12/26',
      icon: Icons.credit_card_rounded,
      isDefault: true,
    ),
    _PaymentMethod(
      label: 'Touch \'n Go e-Wallet',
      subtitle: 'Linked',
      icon: Icons.account_balance_wallet_outlined,
      isDefault: false,
    ),
    _PaymentMethod(
      label: 'GrabPay',
      subtitle: 'Linked',
      icon: Icons.phone_android_rounded,
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          FadeIn(
            delay: Duration.zero,
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.payment_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved methods',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_methods.length} payment methods',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_methods.length, (i) {
            final m = _methods[i];
            return FadeIn(
              delay: Duration(milliseconds: 80 + (i * 60)),
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _methodTile(context, m),
              ),
            );
          }),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 280),
            duration: const Duration(milliseconds: 400),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add payment method'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(BuildContext context, _PaymentMethod m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(m.icon, color: AppColors.primaryLight, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (m.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    m.subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (m.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tagGreenBg,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Text(
                'Default',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tagGreenText,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.iconMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
