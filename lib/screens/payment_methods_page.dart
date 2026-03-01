import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/payment_method.dart';
import '../services/database_helper.dart';
import '../widgets/fade_in_widget.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<PaymentMethod> _methods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _isLoading = true);
    try {
      final methods = await DatabaseHelper.instance.getAllPaymentMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('DB error: $e');
    }
  }

  // ── ADD ──────────────────────────────────────────────────────────────────

  Future<void> _showAddDialog() async {
    String selectedType = 'Card';
    final labelCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xxl)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Payment Method',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 20),
                const Text('Type',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Card', child: Text('Card')),
                    DropdownMenuItem(
                        value: 'e-Wallet', child: Text('e-Wallet')),
                    DropdownMenuItem(
                        value: 'Bank Transfer',
                        child: Text('Bank Transfer')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'Card'),
                ),
                const SizedBox(height: 16),
                const Text('Label',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody)),
                const SizedBox(height: 6),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Maybank **** 1234',
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
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && labelCtrl.text.trim().isNotEmpty) {
      await DatabaseHelper.instance.insertPaymentMethod(
        PaymentMethod(type: selectedType, label: labelCtrl.text.trim()),
      );
      await _loadMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }

    labelCtrl.dispose();
  }

  // ── DELETE ───────────────────────────────────────────────────────────────

  Future<void> _deleteMethod(PaymentMethod m) async {
    if (_methods.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least one payment method')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Remove Payment Method'),
        content: Text('Remove "${m.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deletePaymentMethod(m.id!);
      await _loadMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method removed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── BUILD ───────────────────────────────────────────────────────────────

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // ── Summary header ──
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.payment_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saved methods',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${_methods.length} payment method${_methods.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Method cards ──
                ...List.generate(_methods.length, (i) {
                  final m = _methods[i];
                  return FadeIn(
                    delay: Duration(milliseconds: 80 + (i * 60)),
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _methodTile(m, isDefault: i == 0),
                    ),
                  );
                }),

                // ── Add button ──
                const SizedBox(height: 8),
                FadeIn(
                  delay: Duration(
                      milliseconds: 80 + (_methods.length * 60)),
                  duration: const Duration(milliseconds: 400),
                  child: OutlinedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add payment method'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(
                          color: AppColors.primaryLight),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _methodTile(PaymentMethod m, {bool isDefault = false}) {
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
                Text(m.label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(m.type,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tagGreenBg,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Text('Default',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tagGreenText)),
            ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.iconMuted),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
            onSelected: (v) {
              if (v == 'delete') _deleteMethod(m);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Remove',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
