import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/fade_in_widget.dart';
import 'help_support_page.dart';
import 'history_page.dart';
import 'notification_page.dart';
import 'payment_methods_page.dart';

class ProfilePage extends StatefulWidget {
  final UserProfileProvider profileProvider;
  const ProfilePage({super.key, required this.profileProvider});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfileProvider get _profile => widget.profileProvider;

  bool _editing = false;
  late TextEditingController _nameCtrl;
  String? _pendingPhotoPath; // local preview before saving
  bool _photoRemoved = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _profile.displayName);
    _profile.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  // ── Edit mode helpers ──────────────────────────────────────────────────

  void _enterEdit() {
    setState(() {
      _editing = true;
      _nameCtrl.text = _profile.displayName;
      _pendingPhotoPath = null;
      _photoRemoved = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _pendingPhotoPath = null;
      _photoRemoved = false;
    });
  }

  Future<void> _saveEdit() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isNotEmpty && newName != _profile.displayName) {
      await _profile.updateName(newName);
    }
    if (_photoRemoved) {
      await _profile.removePhoto();
    } else if (_pendingPhotoPath != null) {
      await _profile.updatePhoto(_pendingPhotoPath!);
    }

    if (mounted) {
      setState(() {
        _editing = false;
        _pendingPhotoPath = null;
        _photoRemoved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Photo picker ───────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pendingPhotoPath = picked.path;
        _photoRemoved = false;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Change Profile Photo',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: const Text('Take Photo',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: const Text('Choose from Gallery',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              // Show remove option only if there's a photo to remove
              if (_pendingPhotoPath != null ||
                  (!_photoRemoved && _profile.photoPath != null))
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFC62828), size: 22),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC62828))),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pendingPhotoPath = null;
                      _photoRemoved = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Resolve which photo to display ─────────────────────────────────────

  /// Returns the photo path to display, considering pending edits.
  String? get _displayPhotoPath {
    if (_editing) {
      if (_photoRemoved) return null;
      return _pendingPhotoPath ?? _profile.photoPath;
    }
    return _profile.photoPath;
  }

  // ── Build ──────────────────────────────────────────────────────────────

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
    final photoPath = _displayPhotoPath;

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
          // ── Top row – settings / save+cancel ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_editing) ...[
                // Cancel button
                GestureDetector(
                  onTap: _cancelEdit,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Center(
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Save button
                GestureDetector(
                  onTap: _saveEdit,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Center(
                      child: Text('Save',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ] else
                // Settings gear
                GestureDetector(
                  onTap: _enterEdit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Avatar ──
          GestureDetector(
            onTap: _editing ? _showPhotoOptions : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 3),
                    color: AppColors.surface,
                  ),
                  child: ClipOval(
                    child: photoPath != null
                        ? Image.file(
                            File(photoPath),
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person,
                            color: AppColors.primary, size: 44),
                  ),
                ),
                if (_editing)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 13),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Name ──
          if (_editing)
            SizedBox(
              width: 220,
              child: TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: 'Your name',
                  hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                      fontSize: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            )
          else
            Text(_profile.displayName,
                style: const TextStyle(
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
                    size: 16, color: Colors.amber.shade700),
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

  Widget _dividerVert() =>
      Container(width: 1, height: 36, color: AppColors.divider);

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
