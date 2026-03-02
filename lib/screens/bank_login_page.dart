import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/payment_method.dart';

/// Simulated FPX bank login page.
/// Returns the masked account number (String) on success, or null if cancelled.
class BankLoginPage extends StatefulWidget {
  final PaymentProvider provider;
  final double amount;

  const BankLoginPage({
    super.key,
    required this.provider,
    required this.amount,
  });

  @override
  State<BankLoginPage> createState() => _BankLoginPageState();
}

class _BankLoginPageState extends State<BankLoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoggingIn = false;
  bool _isLoggedIn = false;
  bool _isPaying = false;
  bool _paySuccess = false;

  // Bank-specific theming
  Color get _brandColor {
    switch (widget.provider.name) {
      case 'Maybank':
        return const Color(0xFFFFC629); // Maybank yellow
      case 'CIMB':
        return const Color(0xFFED1C24); // CIMB red
      default:
        return AppColors.primary;
    }
  }

  Color get _brandDark {
    switch (widget.provider.name) {
      case 'Maybank':
        return const Color(0xFF1C1C1C);
      case 'CIMB':
        return const Color(0xFF8B0000);
      default:
        return AppColors.primary;
    }
  }

  Color get _brandTextOnColor {
    switch (widget.provider.name) {
      case 'Maybank':
        return Colors.black;
      case 'CIMB':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) return;

    setState(() => _isLoggingIn = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isLoggingIn = false;
      _isLoggedIn = true;
    });
  }

  Future<void> _pay() async {
    setState(() => _isPaying = true);
    // Simulate payment processing
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _isPaying = false;
      _paySuccess = true;
    });

    // Wait briefly to show success then pop
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final accountNum = _userCtrl.text.trim();
    Navigator.pop(context, accountNum);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: _brandTextOnColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                widget.provider.logoAsset,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 28),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${widget.provider.name} Online',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _brandTextOnColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _paySuccess
            ? _buildSuccess()
            : _isLoggedIn
                ? _buildConfirmation()
                : _buildLoginForm(),
      ),
    );
  }

  // ── Login form ──────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      key: const ValueKey('login'),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.provider.logoAsset,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.account_balance_rounded,
                          size: 36,
                          color: _brandColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.provider.name} Online Banking',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.amount > 0
                      ? 'Log in to authorize payment of RM ${widget.amount.toStringAsFixed(2)}'
                      : 'Log in to link your bank account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Username
          const Text('Username / Account Number',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody)),
          const SizedBox(height: 8),
          TextField(
            controller: _userCtrl,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Enter your username',
              prefixIcon:
                  const Icon(Icons.person_outline_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: _brandColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Password
          const Text('Password',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody)),
          const SizedBox(height: 8),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20),
                onPressed: () =>
                    setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: _brandColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoggingIn ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: _brandTextOnColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: _isLoggingIn
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _brandTextOnColor,
                      ),
                    )
                  : const Text('Log In',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 20),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded,
                  size: 14, color: _brandColor),
              const SizedBox(width: 6),
              Text(
                'Secured by FPX',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _brandColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Payment confirmation ────────────────────────────────────────────────────

  Widget _buildConfirmation() {
    return SingleChildScrollView(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        children: [
          // Checkmark
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: _brandColor, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Login Successful',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(
            'Logged in as ${_userCtrl.text.trim()}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted),
          ),

          const SizedBox(height: 28),

          // Payment summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Details',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 14),
                _row('Bank', widget.provider.name),
                const SizedBox(height: 8),
                _row('To', 'DanaKita Fundraising'),
                const SizedBox(height: 8),
                _row('Account', _userCtrl.text.trim()),
                if (widget.amount > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                        color: _brandColor.withValues(alpha: 0.2)),
                  ),
                  _row(
                    'Amount',
                    'RM ${widget.amount.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: _brandTextOnColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: _isPaying
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _brandTextOnColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Processing...',
                            style: TextStyle(
                                color: _brandTextOnColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Text(
                      widget.amount > 0
                          ? 'Pay RM ${widget.amount.toStringAsFixed(2)}'
                          : 'Link Account',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Success ─────────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Payment Authorized',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Redirecting...',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: bold ? AppColors.textDark : AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? _brandColor : AppColors.textDark)),
      ],
    );
  }
}
