import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../models/payment_method.dart';
import '../services/database_helper.dart';
import '../widgets/fade_in_widget.dart';
import 'bank_login_page.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<PaymentMethod> _methods = [];
  bool _isLoading = true;
  int? _defaultId;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  /// Only used on initial load.
  Future<void> _loadMethods() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final methods = await DatabaseHelper.instance.getAllPaymentMethods();
      // Load persisted default
      final prefs = await SharedPreferences.getInstance();
      final savedDefault = prefs.getInt('default_payment_id');
      if (!mounted) return;
      setState(() {
        _methods = methods;
        if (savedDefault != null && methods.any((m) => m.id == savedDefault)) {
          _defaultId = savedDefault;
        } else if (_defaultId == null || !methods.any((m) => m.id == _defaultId)) {
          _defaultId = methods.isNotEmpty ? methods.first.id : null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('DB error: $e');
    }
  }

  /// Schedule a setState for the next frame — avoids conflicts with
  /// InheritedNotifier dependency tracking during route transitions.
  void _safeSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  /// Safe snackbar helper — also deferred to next frame.
  void _showSnack(String message, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    });
  }

  void _setDefault(PaymentMethod m) {
    _safeSetState(() => _defaultId = m.id);
    // Persist to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('default_payment_id', m.id!);
    });
    _showSnack('${m.provider} set as default', AppColors.primary);
  }

  // ── ADD FLOW ──────────────────────────────────────────────────────────────

  Future<void> _showAddFlow() async {
    // Step 1: pick type
    final type = await _pickType();
    if (type == null || !mounted) return;

    // Step 2: pick provider
    final provider = await _pickProvider(type);
    if (provider == null || !mounted) return;

    // Step 3: FPX banks → bank login page, others → credential dialog
    String? result;
    if (type == 'FPX') {
      result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => BankLoginPage(
            provider: provider,
            amount: 0,
          ),
        ),
      );
    } else {
      result = await _enterCredentials(type, provider);
    }
    if (result == null || !mounted) return;

    // Save to DB
    final masked = maskCredential(result);
    final newMethod = PaymentMethod(
      type: type,
      provider: provider.name,
      label: '${provider.name} $masked',
      credential: masked,
    );

    try {
      final id = await DatabaseHelper.instance.insertPaymentMethod(newMethod);
      if (!mounted) return;
      // Update list in-memory — deferred to next frame for safety
      _safeSetState(() => _methods = [..._methods, newMethod.copyWith(id: id)]);
      _showSnack('Payment method added', AppColors.primary);
    } catch (e) {
      debugPrint('Error inserting payment method: $e');
    }
  }

  Future<String?> _pickType() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select Payment Type',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 20),
            _typeTile(ctx, 'FPX', 'Online Banking',
                Icons.account_balance_rounded),
            const SizedBox(height: 10),
            _typeTile(
                ctx, 'Card', 'Credit / Debit Card', Icons.credit_card_rounded),
            const SizedBox(height: 10),
            _typeTile(ctx, 'E-Wallet', 'E-Wallet',
                Icons.account_balance_wallet_rounded),
          ],
        ),
      ),
    );
  }

  Widget _typeTile(
      BuildContext ctx, String type, String label, IconData icon) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<PaymentProvider?> _pickProvider(String type) async {
    final providers = providersForType(type);
    return showModalBottomSheet<PaymentProvider>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Select ${type == 'FPX' ? 'Bank' : 'Provider'}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: providers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = providers[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          _providerLogo(p.logoAsset, 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(p.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _enterCredentials(
      String type, PaymentProvider provider) async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    final ctrl3 = TextEditingController();

    String title;
    String hint1;
    String? hint2, hint3;
    List<TextInputFormatter>? fmt1;
    TextInputType kb1;

    switch (type) {
      case 'Card':
        title = 'Card Details';
        hint1 = 'Card Number';
        hint2 = 'Expiry (MM/YY)';
        hint3 = 'CVV';
        kb1 = TextInputType.number;
        fmt1 = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          _CardNumberFormatter(),
        ];
        break;
      case 'FPX':
        title = 'Bank Account';
        hint1 = 'Account Number';
        kb1 = TextInputType.number;
        fmt1 = [FilteringTextInputFormatter.digitsOnly];
        break;
      default: // E-Wallet
        title = 'E-Wallet Details';
        hint1 = 'Phone Number';
        kb1 = TextInputType.phone;
        fmt1 = [FilteringTextInputFormatter.digitsOnly];
        break;
    }

    final result = await showDialog<String>(
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
              Row(
                children: [
                  _providerLogo(provider.logoAsset, 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text(provider.name,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl1,
                keyboardType: kb1,
                inputFormatters: fmt1,
                decoration: InputDecoration(
                  hintText: hint1,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              if (hint2 != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl2,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d/]')),
                          LengthLimitingTextInputFormatter(5),
                        ],
                        decoration: InputDecoration(
                          hintText: hint2,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    if (hint3 != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: ctrl3,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            hintText: hint3,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (ctrl1.text.trim().isEmpty) return;
                        Navigator.pop(ctx, ctrl1.text.trim());
                      },
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

    // Do not immediately dispose controllers here; the Dialog is still animating out for ~300ms.
    // Disposing them instantly causes the TextFields to crash during the route transition,
    // which corrupts the unmount sequence and triggers the `_dependents.isEmpty` assertion.
    return result;
  }

  // ── DELETE ───────────────────────────────────────────────────────────────

  Future<void> _deleteMethod(PaymentMethod m) async {
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

    if (confirm != true || !mounted) return;

    try {
      await DatabaseHelper.instance.deletePaymentMethod(m.id!);
      if (!mounted) return;
      // Update list in-memory — deferred to next frame for safety
      _safeSetState(() => _methods = _methods.where((x) => x.id != m.id).toList());
      _showSnack('Payment method removed', AppColors.error);
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
    }
  }

  // ── EDIT ─────────────────────────────────────────────────────────────────

  Future<void> _editMethod(PaymentMethod m) async {
    final labelCtrl = TextEditingController(text: m.label);

    final newLabel = await showDialog<String>(
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
              Row(
                children: [
                  _providerLogo(m.logoPath, 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Payment Method',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text(m.provider,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g. My Personal Card',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final text = labelCtrl.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(ctx, text);
                      },
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

    // Do not immediately dispose labelCtrl here to prevent TextField unmount crash.

    if (newLabel == null || !mounted) return;

    try {
      final updated = m.copyWith(label: newLabel);
      await DatabaseHelper.instance.updatePaymentMethod(updated);
      if (!mounted) return;
      // Update list in-memory — deferred to next frame for safety
      _safeSetState(() {
        _methods =
            _methods.map((x) => x.id == updated.id ? updated : x).toList();
      });
      _showSnack('Payment method updated', AppColors.primary);
    } catch (e) {
      debugPrint('Error updating payment method: $e');
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

                // ── Empty state ──
                if (_methods.isEmpty)
                  FadeIn(
                    delay: const Duration(milliseconds: 80),
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.credit_card_off_rounded,
                              color: AppColors.textMuted,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No payment methods saved',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add a payment method to get started',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Method cards ──
                ...List.generate(_methods.length, (i) {
                  final m = _methods[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _methodTile(m, isDefault: m.id == _defaultId),
                  );
                }),

                // ── Add button ──
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showAddFlow,
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
              ],
            ),
    );
  }

  Widget _methodTile(PaymentMethod m, {bool isDefault = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefault ? AppColors.light : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isDefault
            ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4))
            : null,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _providerLogo(m.logoPath, 36),
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
              // Delay by one frame so the popup menu route fully closes
              // before we push another dialog/bottom-sheet.
              Future.delayed(Duration.zero, () {
                if (!mounted) return;
                if (v == 'delete') _deleteMethod(m);
                if (v == 'default') _setDefault(m);
                if (v == 'edit') _editMethod(m);
              });
            },
            itemBuilder: (_) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Set as default',
                          style: TextStyle(color: AppColors.textDark)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text('Edit',
                        style: TextStyle(color: AppColors.textDark)),
                  ],
                ),
              ),
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

// ── Shared logo widget ───────────────────────────────────────────────────────

Widget _providerLogo(String path, double size) {
  if (path.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(Icons.payment_rounded,
          color: AppColors.textMuted, size: size * 0.5),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(Icons.payment_rounded,
            color: AppColors.textMuted, size: size * 0.5),
      ),
    ),
  );
}

// ── Card number formatter ────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
