import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/fade_in_widget.dart';
import 'help_support_page.dart';
import 'history_page.dart';
import 'notification_page.dart';
import 'payment_methods_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          FadeIn(
            delay: Duration.zero,
            duration: const Duration(milliseconds: 450),
            child: _buildHeader(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                FadeIn(
                  delay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: _buildStatsRow(),
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 160),
                  duration: const Duration(milliseconds: 400),
                  child: _buildMenuCard(context),
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 240),
                  duration: const Duration(milliseconds: 450),
                  child: _buildAboutCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_outlined,
                    color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Avatar
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 3),
              color: AppColors.surface,
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 14),
          const Text('Danish Iskandar',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    size: 16,
                    color: Colors.amber.shade700),
                const SizedBox(width: 4),
                const Text('Super Donor',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _stat('RM 1,200', 'Total Given'),
          _dividerVert(),
          _stat('24', 'Campaigns'),
          _dividerVert(),
          _stat('5', 'Months'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryLight)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _dividerVert() => Container(
      width: 1, height: 36, color: AppColors.divider);

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.history_rounded,
            label: 'Donation History',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage())),
          ),
          const Divider(height: 0, indent: 60),
          _menuItem(
            icon: Icons.payment_rounded,
            label: 'Payment Methods',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsPage())),
          ),
          const Divider(height: 0, indent: 60),
          _menuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          const Divider(height: 0, indent: 60),
          _menuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage())),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.iconMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('About DanaKita',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'DanaKita is a community-driven fundraising platform bridging the gap between generous hearts and those in need.',
            style: TextStyle(
                fontSize: 14, height: 1.6, color: AppColors.textBody),
          ),
          const SizedBox(height: 16),
          _checkRow('100% Transparent Donations'),
          _checkRow('Verified Charity Partners'),
          _checkRow('Secure Payment Process'),
        ],
      ),
    );
  }

  Widget _checkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.primaryLight, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textBody)),
          ),
        ],
      ),
    );
  }
}
