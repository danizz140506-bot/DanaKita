import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../widgets/fade_in_widget.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  // ── URL launcher helper ──────────────────────────────────────────────────

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
            child: _sectionCard(
              icon: Icons.contact_support_rounded,
              title: 'Contact us',
              children: [
                _contactRow(
                  Icons.email_outlined,
                  'support@danakita.my',
                  onTap: () => _launch(context, 'mailto:support@danakita.my'),
                ),
                const SizedBox(height: 12),
                _contactRow(
                  Icons.phone_outlined,
                  '+60 3-1234 5678',
                  onTap: () => _launch(context, 'tel:+60312345678'),
                ),
                const SizedBox(height: 12),
                _contactRow(
                  Icons.schedule_rounded,
                  'Mon\u2013Fri, 9am\u20136pm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeIn(
            delay: const Duration(milliseconds: 80),
            duration: const Duration(milliseconds: 400),
            child: _sectionCard(
              icon: Icons.help_outline_rounded,
              title: 'Frequently asked questions',
              children: [
                _faqItem(
                  'How do I make a donation?',
                  'Tap any campaign, then use "Donate Now" and follow the steps to enter amount and payment method.',
                ),
                _faqItem(
                  'Is my donation secure?',
                  'Yes. We use secure payment processing and do not store your full card details.',
                ),
                _faqItem(
                  'Can I get a receipt?',
                  'Yes. Receipts are available in your Profile under Donation History.',
                ),
                _faqItem(
                  'How do I save a campaign?',
                  'Open a campaign and tap the heart icon in the app bar to add it to Saved.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeIn(
            delay: const Duration(milliseconds: 160),
            duration: const Duration(milliseconds: 400),
            child: _sectionCard(
              icon: Icons.description_outlined,
              title: 'Resources',
              children: [
                _resourceRow('Terms of Service',
                    () => _launch(context, 'https://danakita.my/terms')),
                _resourceRow('Privacy Policy',
                    () => _launch(context, 'https://danakita.my/privacy')),
                _resourceRow('Community Guidelines',
                    () => _launch(context, 'https://danakita.my/guidelines')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, {VoidCallback? onTap}) {
    final row = Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: onTap != null ? AppColors.primaryLight : AppColors.textBody,
              fontWeight: onTap != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.iconMuted),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourceRow(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
