import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/payment_result.dart';
import '../services/payment_api_service.dart';

class DonatePage extends StatefulWidget {
  final String? campaignTitle;
  const DonatePage({super.key, this.campaignTitle});
  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final _ctrl = TextEditingController(text: '50.00');
  int _presetIdx = 1;
  int _payIdx = 0;
  bool _tip = false;

  static const _presets = [10.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final v = double.tryParse(_ctrl.text.trim().replaceAll(',', ''));
      if (v != null && !_presets.contains(v)) {
        setState(() => _presetIdx = -1);
      }
    });
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

  bool _isProcessing = false;

  Future<void> _confirm() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid donation amount')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentApiService.processPayment(
        amount: _amount,
        tip: _tipAmt,
        total: _total,
        paymentMethod: _payIdx == 0 ? 'Card' : 'e-Wallet',
        campaign: widget.campaignTitle ?? 'General Fund',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

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
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.primaryLight, size: 40),
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

                  // ── Payment method ──
                  _sectionLabel('Payment Method'),
                  const SizedBox(height: 12),
                  _payOption(
                      0, 'Card', 'Visa ending in 4242', Icons.credit_card),
                  const SizedBox(height: 10),
                  _payOption(1, 'e-Wallet', 'Touch \'n Go / e-Wallet',
                      Icons.account_balance_wallet_rounded),

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
                        _row('Donation',
                            'RM ${_amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 10),
                        _row('Developer tip',
                            'RM ${_tipAmt.toStringAsFixed(2)}'),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.primaryLight
                              .withValues(alpha: 0.2)),
                        ),
                        _row('Total',
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
          Container(
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
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        boxShadow: _isProcessing ? [] : AppShadows.glow,
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Processing...',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded,
                                    color: AppColors.primary, size: 22),
                                SizedBox(width: 8),
                                Text('Confirm Donation',
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
                    const Icon(Icons.lock_rounded,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text('Secure SSL Encrypted',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark));

  Widget _payOption(int idx, String title, String sub, IconData icon) {
    final sel = _payIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _payIdx = idx),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: sel ? AppColors.primaryLight : AppColors.border,
            width: sel ? 2 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primaryLight.withValues(alpha: 0.1)
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon,
                  size: 22,
                  color: sel ? AppColors.primaryLight : AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? AppColors.primaryLight
                              : AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(
              sel
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: sel ? AppColors.primaryLight : AppColors.iconMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
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
