import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/donation.dart';
import '../models/payment_method.dart';
import '../models/payment_result.dart';
import '../services/database_helper.dart';
import '../services/payment_api_service.dart';

// ── Payment category data (no DuitNow QR) ────────────────────────────────────

class _PayCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final String type; // maps to PaymentProvider.type
  const _PayCategory(this.title, this.subtitle, this.icon, this.type);
}

const _categories = [
  _PayCategory('FPX Online Banking', 'Pay directly from your bank',
      Icons.account_balance_rounded, 'FPX'),
  _PayCategory('Credit / Debit Card', 'Visa, Mastercard',
      Icons.credit_card_rounded, 'Card'),
  _PayCategory('E-Wallet', 'Touch \'n Go, GrabPay & more',
      Icons.account_balance_wallet_rounded, 'E-Wallet'),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class DonatePage extends StatefulWidget {
  final String? campaignTitle;
  const DonatePage({super.key, this.campaignTitle});
  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final _ctrl = TextEditingController(text: '50.00');
  int _presetIdx = 1;
  bool _tip = false;

  // Saved methods from DB
  List<PaymentMethod> _savedMethods = [];
  int? _savedMethodIdx; // selected saved method index

  // Accordion state
  int? _expandedCat;
  String? _selectedProvider; // provider name selected from accordion

  static const _presets = [10.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _loadSavedMethods();
    _ctrl.addListener(() {
      final v = double.tryParse(_ctrl.text.trim().replaceAll(',', ''));
      if (v != null && !_presets.contains(v)) {
        setState(() => _presetIdx = -1);
      }
    });
  }

  Future<void> _loadSavedMethods() async {
    try {
      final methods = await DatabaseHelper.instance.getAllPaymentMethods();
      if (!mounted) return;
      setState(() {
        _savedMethods = methods;
        // Auto-select first saved method
        if (_savedMethods.isNotEmpty && _savedMethodIdx == null) {
          _savedMethodIdx = 0;
        }
      });
    } catch (_) {}
  }

  String get _selectedPayName {
    if (_savedMethodIdx != null && _savedMethodIdx! < _savedMethods.length) {
      return _savedMethods[_savedMethodIdx!].label;
    }
    if (_selectedProvider != null) return _selectedProvider!;
    return '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_ctrl.text.trim().replaceAll(',', '')) ?? 0;
  double get _tipAmt => _tip ? _amount * 0.05 : 0;
  double get _total => _amount + _tipAmt;

  void _pickPreset(int i) {
    setState(() {
      _presetIdx = _presetIdx == i ? -1 : i;
      if (_presetIdx >= 0) _ctrl.text = _presets[i].toStringAsFixed(2);
    });
  }

  void _selectSaved(int idx) {
    setState(() {
      _savedMethodIdx = idx;
      _selectedProvider = null; // clear accordion selection
      _expandedCat = null;
    });
  }

  void _selectFromAccordion(PaymentProvider provider) {
    // Check if user already has this provider saved
    final existing = _savedMethods.indexWhere(
        (m) => m.provider == provider.name);
    if (existing >= 0) {
      _selectSaved(existing);
      return;
    }

    // Not saved — prompt to add credentials
    _promptAddCredentials(provider);
  }

  Future<void> _promptAddCredentials(PaymentProvider provider) async {
    final credential = await _showCredentialDialog(provider);
    if (credential == null || !mounted) return;

    final masked = maskCredential(credential);
    await DatabaseHelper.instance.insertPaymentMethod(
      PaymentMethod(
        type: provider.type,
        provider: provider.name,
        label: '${provider.name} $masked',
        credential: masked,
      ),
    );
    await _loadSavedMethods();

    // Select the newly added method
    if (mounted) {
      final newIdx = _savedMethods.indexWhere(
          (m) => m.provider == provider.name);
      if (newIdx >= 0) {
        setState(() {
          _savedMethodIdx = newIdx;
          _selectedProvider = null;
          _expandedCat = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.name} added & selected'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<String?> _showCredentialDialog(PaymentProvider provider) async {
    final ctrl = TextEditingController();
    String hint;
    TextInputType kb;
    List<TextInputFormatter>? fmt;

    switch (provider.type) {
      case 'Card':
        hint = 'Card Number';
        kb = TextInputType.number;
        fmt = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
        ];
        break;
      case 'FPX':
        hint = 'Account Number';
        kb = TextInputType.number;
        fmt = [FilteringTextInputFormatter.digitsOnly];
        break;
      default:
        hint = 'Phone Number';
        kb = TextInputType.phone;
        fmt = [FilteringTextInputFormatter.digitsOnly];
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
                  _logo(provider.logoAsset, 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add ${provider.name}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text('Enter your $hint',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType: kb,
                inputFormatters: fmt,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 20),
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
                        if (ctrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx, ctrl.text.trim());
                      },
                      child: const Text('Add & Pay'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    ctrl.dispose();
    return result;
  }

  bool _isProcessing = false;

  Future<void> _confirm() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid donation amount')),
      );
      return;
    }
    if (_selectedPayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentApiService.processPayment(
        amount: _amount,
        tip: _tipAmt,
        total: _total,
        paymentMethod: _selectedPayName,
        campaign: widget.campaignTitle ?? 'General Fund',
      );

      await DatabaseHelper.instance.insertDonation(Donation(
        campaign: widget.campaignTitle ?? 'General Fund',
        amount: _amount,
        tip: _tipAmt,
        total: _total,
        paymentMethod: _selectedPayName,
        transactionId: result.formattedId,
        date: DateTime.now().toIso8601String(),
      ));

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.light,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Thank You!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(
                'Your donation of RM ${_amount.toStringAsFixed(2)} has been received.${widget.campaignTitle != null ? '\nSupporting "${widget.campaignTitle}"' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textBody),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Transaction ID: ${result.formattedId}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Payment Failed',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textBody)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Donate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Amount section ──
                  _sectionLabel('Donation Amount'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border:
                          Border.all(color: AppColors.primaryLight, width: 2),
                      boxShadow: AppShadows.card,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    child: Row(
                      children: [
                        const Text('RM',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                              hintStyle: TextStyle(color: AppColors.textHint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(_presets.length, (i) {
                      final sel = i == _presetIdx;
                      return Padding(
                        padding: EdgeInsets.only(
                            right: i < _presets.length - 1 ? 10 : 0),
                        child: GestureDetector(
                          onTap: () => _pickPreset(i),
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primaryLight
                                  : AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              border: sel
                                  ? null
                                  : Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'RM ${_presets[i].toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textBody,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // ── Saved payment methods ──
                  if (_savedMethods.isNotEmpty) ...[
                    _sectionLabel('Your Payment Methods'),
                    const SizedBox(height: 12),
                    ..._savedMethods.asMap().entries.map((entry) {
                      final i = entry.key;
                      final m = entry.value;
                      final sel = _savedMethodIdx == i &&
                          _selectedProvider == null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _selectSaved(i),
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.light
                                  : AppColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primaryLight
                                    : AppColors.border,
                                width: sel ? 2 : 1,
                              ),
                              boxShadow: AppShadows.card,
                            ),
                            child: Row(
                              children: [
                                _logo(m.logoPath, 42),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.provider,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: sel
                                                  ? AppColors.primaryLight
                                                  : AppColors.textDark)),
                                      Text(m.credential,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                if (sel)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check,
                                        size: 16, color: Colors.white),
                                  )
                                else
                                  Icon(Icons.radio_button_off,
                                      color: AppColors.iconMuted, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // ── Accordion: "Or pay with" ──
                  _sectionLabel(
                      _savedMethods.isNotEmpty ? 'Or pay with' : 'Payment Method'),
                  const SizedBox(height: 12),
                  ...List.generate(_categories.length, _buildCategory),

                  const SizedBox(height: 24),

                  // ── Tip ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: CheckboxListTile(
                      value: _tip,
                      onChanged: (v) => setState(() => _tip = v ?? false),
                      title: const Text('Leave a developer tip',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: _tip
                          ? Text(
                              '5% \u2022 RM ${_tipAmt.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted))
                          : null,
                      activeColor: AppColors.primaryLight,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Summary ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Donation',
                            'RM ${_amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 10),
                        _summaryRow('Developer tip',
                            'RM ${_tipAmt.toStringAsFixed(2)}'),
                        if (_selectedPayName.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _summaryRow('Pay via', _selectedPayName),
                        ],
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.primaryLight
                              .withValues(alpha: 0.2)),
                        ),
                        _summaryRow('Total',
                            'RM ${_total.toStringAsFixed(2)}',
                            bold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Confirm button ──
          _buildConfirmBar(),
        ],
      ),
    );
  }

  // ── Accordion category ─────────────────────────────────────────────────────

  Widget _buildCategory(int catIdx) {
    final cat = _categories[catIdx];
    final isExpanded = _expandedCat == catIdx;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isExpanded
                ? AppColors.primaryLight.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // ── Header ──
            GestureDetector(
              onTap: () => setState(() {
                _expandedCat = isExpanded ? null : catIdx;
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isExpanded ? AppColors.light : AppColors.white,
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg))
                      : BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.primaryLight.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(cat.icon,
                          size: 22,
                          color: isExpanded
                              ? AppColors.primaryLight
                              : AppColors.textMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isExpanded
                                      ? AppColors.primaryLight
                                      : AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(cat.subtitle,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: AppDurations.fast,
                      child: const Icon(Icons.expand_more_rounded,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // ── Options (expanded) ──
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildProviderGrid(catIdx),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppDurations.fast,
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  // ── Provider grid inside a category ────────────────────────────────────────

  Widget _buildProviderGrid(int catIdx) {
    final cat = _categories[catIdx];
    final providers = providersForType(cat.type);

    // Cards: horizontal row
    if (cat.type == 'Card') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: providers.map((p) {
            final isSaved = _savedMethods.any((m) => m.provider == p.name);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: p != providers.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _selectFromAccordion(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        _logo(p.logoAsset, 36),
                        const SizedBox(height: 6),
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textBody)),
                        if (isSaved)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle_rounded,
                                color: AppColors.primaryLight, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // FPX banks & E-Wallets: 2-column grid with logos
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
        ),
        itemCount: providers.length,
        itemBuilder: (context, i) {
          final p = providers[i];
          final isSaved = _savedMethods.any((m) => m.provider == p.name);
          return GestureDetector(
            onTap: () => _selectFromAccordion(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  _logo(p.logoAsset, 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                  ),
                  if (isSaved)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primaryLight, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Confirm bar ────────────────────────────────────────────────────────────

  Widget _buildConfirmBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: GestureDetector(
              onTap: _isProcessing ? null : _confirm,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? AppColors.soft.withValues(alpha: 0.5)
                      : AppColors.soft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: _isProcessing ? [] : AppShadows.glow,
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Processing...',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Pay Securely',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 5),
              Text('Secured by DanaKita',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark));

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: bold ? AppColors.textDark : AppColors.textMuted,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 18 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? AppColors.primaryLight : AppColors.textDark)),
      ],
    );
  }
}

// ── Logo widget ──────────────────────────────────────────────────────────────

Widget _logo(String path, double size) {
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
      fit: BoxFit.cover,
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
