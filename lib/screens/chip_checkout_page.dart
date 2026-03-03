import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/payment_method.dart';
import '../models/payment_result.dart';
import '../services/payment_api_service.dart';

// ── CHIP brand colors ────────────────────────────────────────────────────────

const _chipPurple = Color(0xFF5147DD);
const _chipPink = Color(0xFFDD80DD);
const _chipBg = Color(0xFFF7F9FC);

/// Mock CHIP payment gateway checkout page.
///
/// Simulates a redirect to CHIP's hosted payment page where the user
/// enters their credentials. No credentials are stored locally — everything
/// stays on this screen (mocking the external gateway).
class ChipCheckoutPage extends StatefulWidget {
  final PaymentMethod method;
  final double amount;
  final double tip;
  final double total;
  final String campaign;
  final bool isLinked;

  const ChipCheckoutPage({
    super.key,
    required this.method,
    required this.amount,
    required this.tip,
    required this.total,
    required this.campaign,
    this.isLinked = false,
  });

  @override
  State<ChipCheckoutPage> createState() => _ChipCheckoutPageState();
}

class _ChipCheckoutPageState extends State<ChipCheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // Card fields
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  // FPX / E-Wallet fields
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isProcessing = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isCard => widget.method.type == 'Card';
  bool get _isFpx => widget.method.type == 'FPX';
  bool get _isEWallet => widget.method.type == 'E-Wallet';

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentApiService.processPayment(
        amount: widget.amount,
        tip: widget.tip,
        total: widget.total,
        paymentMethod: widget.method.provider,
        campaign: widget.campaign,
      );

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _chipBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_chipPurple, _chipPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/chip-logo.svg',
              height: 22,
            ),
            const SizedBox(width: 8),
            const Text('Checkout',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Amount card ──
                    _buildAmountCard(),
                    const SizedBox(height: 24),

                    // ── Provider info ──
                    _buildProviderHeader(),
                    const SizedBox(height: 20),

                    // ── Credential fields ──
                    if (!widget.isLinked) ...[
                      if (_isCard) _buildCardFields(),
                      if (_isFpx) _buildFpxFields(),
                      if (_isEWallet) _buildEWalletFields(),
                      const SizedBox(height: 24),
                    ],

                    // ── Security note ──
                    _buildSecurityNote(),
                  ],
                ),
              ),
            ),
          ),

          // ── Pay button ──
          _buildPayBar(),
        ],
      ),
    );
  }

  // ── Amount card ────────────────────────────────────────────────────────────

  Widget _buildAmountCard() {
    if (widget.total <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_chipPurple, _chipPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33003366),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Payment Amount',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xAAFFFFFF),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('RM ${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1)),
          if (widget.tip > 0) ...[
            const SizedBox(height: 6),
            Text(
                'Includes RM ${widget.tip.toStringAsFixed(2)} developer tip',
                style: const TextStyle(
                    fontSize: 12, color: Color(0x99FFFFFF))),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(widget.campaign,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xCCFFFFFF))),
          ),
        ],
      ),
    );
  }

  // ── Provider header ────────────────────────────────────────────────────────

  Widget _buildProviderHeader() {
    final isLinking = widget.total <= 0;
    return Row(
      children: [
        _providerLogo(widget.method.logoPath, 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isLinking ? 'Link ${widget.method.provider}' : 'Pay with ${widget.method.provider}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(widget.method.type,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card credential fields ─────────────────────────────────────────────────

  Widget _buildCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Card Number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cardCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          decoration: _inputDecoration(
            hint: '1234 5678 9012 3456',
            icon: Icons.credit_card_rounded,
          ),
          validator: (v) {
            final digits = (v ?? '').replaceAll(' ', '');
            if (digits.length < 13) return 'Enter a valid card number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Expiry'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                      LengthLimitingTextInputFormatter(5),
                      _ExpiryFormatter(),
                    ],
                    decoration: _inputDecoration(
                      hint: 'MM/YY',
                      icon: Icons.calendar_today_rounded,
                    ),
                    validator: (v) {
                      if ((v ?? '').length < 5) return 'MM/YY';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('CVV'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _inputDecoration(
                      hint: '•••',
                      icon: Icons.lock_rounded,
                    ),
                    validator: (v) {
                      if ((v ?? '').length < 3) return 'Invalid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── FPX credential fields ──────────────────────────────────────────────────

  Widget _buildFpxFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Username / User ID'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountCtrl,
          keyboardType: TextInputType.text,
          decoration: _inputDecoration(
            hint: 'Enter your online banking ID',
            icon: Icons.person_rounded,
          ),
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return 'Please enter your user ID';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            hint: 'Enter your password',
            icon: Icons.lock_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return 'Please enter your password';
            return null;
          },
        ),
      ],
    );
  }

  // ── E-Wallet credential fields ─────────────────────────────────────────────

  Widget _buildEWalletFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Phone Number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: _inputDecoration(
            hint: '01X-XXXX XXXX',
            icon: Icons.phone_android_rounded,
          ),
          validator: (v) {
            if ((v ?? '').length < 10) return 'Enter a valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('PIN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: _inputDecoration(
            hint: '••••••',
            icon: Icons.lock_rounded,
          ),
          validator: (v) {
            if ((v ?? '').length < 4) return 'Enter your PIN';
            return null;
          },
        ),
      ],
    );
  }

  // ── Security note ──────────────────────────────────────────────────────────

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFD0D8E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded,
              size: 20, color: _chipPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Payment',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _chipPurple)),
                const SizedBox(height: 4),
                Text(
                  'Your payment details are encrypted and processed securely by CHIP. '
                  'No credentials are stored on this device.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pay button bar ─────────────────────────────────────────────────────────

  Widget _buildPayBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isProcessing
                    ? [
                        _chipPurple.withValues(alpha: 0.5),
                        _chipPink.withValues(alpha: 0.5)
                      ]
                    : [_chipPurple, _chipPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                elevation: 0,
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
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Processing...',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                            widget.total > 0
                                ? 'Pay RM ${widget.total.toStringAsFixed(2)}'
                                : 'Link Account',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/images/powered-by-chip.svg', height: 24),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody));

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
      prefixIcon:
          Icon(icon, size: 20, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: _chipPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

// ── Provider logo helper ─────────────────────────────────────────────────────

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

// ── Card number formatter (adds spaces every 4 digits) ───────────────────────

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
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Expiry formatter (auto-inserts /) ────────────────────────────────────────

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i == 2) buf.write('/');
      buf.write(text[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
