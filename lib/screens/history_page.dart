import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/donation.dart';
import '../services/database_helper.dart';
import '../widgets/fade_in_widget.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum _SortMode { newestFirst, oldestFirst, highestAmount, lowestAmount }

class _HistoryPageState extends State<HistoryPage> {
  List<Donation> _donations = [];
  double _totalDonated = 0;
  bool _isLoading = true;
  _SortMode _sortMode = _SortMode.newestFirst;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  // ── READ ────────────────────────────────────────────────────────────────

  Future<void> _loadDonations() async {
    setState(() => _isLoading = true);
    try {
      final donations = await DatabaseHelper.instance.getAllDonations();
      final total = await DatabaseHelper.instance.getTotalDonated();
      if (!mounted) return;
      setState(() {
        _donations = donations;
        _totalDonated = total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('DB error: $e');
    }
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────

  Future<void> _editDonation(Donation donation) async {
    String noteText = donation.note;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Donation',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text(donation.campaign,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textBody)),
              const SizedBox(height: 16),
              Text(
                'RM ${donation.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Note',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: noteText,
                onChanged: (val) => noteText = val,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final updated = donation.copyWith(
        note: noteText.trim(),
      );

      await DatabaseHelper.instance.updateDonation(updated);
      await _loadDonations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  // ── DELETE ──────────────────────────────────────────────────────────────

  Future<void> _deleteDonation(Donation donation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Donation'),
        content: Text(
            'Remove the RM ${donation.amount.toStringAsFixed(2)} donation to "${donation.campaign}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteDonation(donation.id!);
      await _loadDonations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── DELETE ALL ────────────────────────────────────────────────────────

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Clear All Donations'),
        content: Text(
            'Delete all ${_donations.length} donation records? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteAllDonations();
      await _loadDonations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All donations cleared'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Donation> get _sortedDonations {
    final list = List<Donation>.from(_donations);
    switch (_sortMode) {
      case _SortMode.newestFirst:
        list.sort((a, b) => b.date.compareTo(a.date));
      case _SortMode.oldestFirst:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _SortMode.highestAmount:
        list.sort((a, b) => b.total.compareTo(a.total));
      case _SortMode.lowestAmount:
        list.sort((a, b) => a.total.compareTo(b.total));
    }
    return list;
  }

  String _sortLabel(_SortMode mode) {
    switch (mode) {
      case _SortMode.newestFirst:
        return 'Newest first';
      case _SortMode.oldestFirst:
        return 'Oldest first';
      case _SortMode.highestAmount:
        return 'Highest amount';
      case _SortMode.lowestAmount:
        return 'Lowest amount';
    }
  }

  IconData _sortIcon(_SortMode mode) {
    switch (mode) {
      case _SortMode.newestFirst:
        return Icons.arrow_downward_rounded;
      case _SortMode.oldestFirst:
        return Icons.arrow_upward_rounded;
      case _SortMode.highestAmount:
        return Icons.trending_up_rounded;
      case _SortMode.lowestAmount:
        return Icons.trending_down_rounded;
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Donation History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_donations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary header ──
          _buildHeader(),

          // ── Sort row ──
          if (_donations.isNotEmpty) _buildSortRow(),

          // ── List ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              Text(
                _isLoading
                    ? 'Loading...'
                    : '${_donations.length} Donation${_donations.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'RM ${_totalDonated.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 6),
          const Text('Sort by',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _SortMode.values.map((mode) {
                  final selected = mode == _sortMode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _sortMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryLight
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: selected
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_sortIcon(mode),
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textBody),
                            const SizedBox(width: 4),
                            Text(_sortLabel(mode),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textBody)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_donations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 56, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No donations yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            SizedBox(height: 8),
            Text('Your donation history will appear here',
                style: TextStyle(fontSize: 13, color: AppColors.textBody)),
          ],
        ),
      );
    }

    final sorted = _sortedDonations;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDonations,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          final donation = sorted[i];
          return FadeIn(
            delay: Duration(milliseconds: 60 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDonationCard(donation),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(Donation donation) {
    return Dismissible(
      key: ValueKey(donation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteDonation(donation);
        return false; // We handle deletion in _deleteDonation
      },
      child: GestureDetector(
        onTap: () => _editDonation(donation),
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(donation.campaign,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(donation.formattedDate,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    if (donation.transactionId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(donation.transactionId,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                    ],
                    if (donation.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(donation.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textBody)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('RM ${donation.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
