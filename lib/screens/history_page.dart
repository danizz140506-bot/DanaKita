import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/fade_in_widget.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _history;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Donation History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.glow,
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
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${items.length} Donations',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('RM 1,200.00',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return FadeIn(
                  delay: Duration(milliseconds: 60 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: AppColors.primaryLight,
                                size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title']!,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text(item['date']!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(item['amount']!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryLight)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.tagGreenBg,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xl),
                                ),
                                child: const Text('Completed',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.tagGreenText)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _history = [
    {'title': 'Emergency Flood Relief', 'amount': 'RM 200.00', 'date': '15 Jan 2025'},
    {'title': 'Build a Dream School', 'amount': 'RM 150.00', 'date': '10 Jan 2025'},
    {'title': 'Clean Water for Everyone', 'amount': 'RM 100.00', 'date': '5 Jan 2025'},
    {'title': 'Emergency Flood Relief', 'amount': 'RM 250.00', 'date': '28 Dec 2024'},
    {'title': 'Build a Dream School', 'amount': 'RM 500.00', 'date': '20 Dec 2024'},
  ];
}
