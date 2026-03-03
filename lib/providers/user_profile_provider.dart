import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's display name and profile photo path.
///
/// Persists data via [SharedPreferences] and notifies listeners on change.
class UserProfileProvider extends ChangeNotifier {
  static const _keyName = 'user_display_name';
  static const _keyPhoto = 'user_photo_path';
  static const defaultName = 'Danish Iskandar';

  String _displayName = defaultName;
  String? _photoPath;
  bool _loaded = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  String get displayName => _displayName;

  /// First word of the display name (used for greeting).
  String get firstName => _displayName.split(' ').first;

  /// The profile photo file, or null if none has been set.
  File? get photoFile =>
      _photoPath != null ? File(_photoPath!) : null;

  String? get photoPath => _photoPath;
  bool get loaded => _loaded;

  // ── Init ─────────────────────────────────────────────────────────────────

  /// Load persisted values. Call once at app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString(_keyName) ?? defaultName;
    _photoPath = prefs.getString(_keyPhoto);
    // Verify the photo file still exists.
    if (_photoPath != null && !File(_photoPath!).existsSync()) {
      _photoPath = null;
      await prefs.remove(_keyPhoto);
    }
    _loaded = true;
    notifyListeners();
  }

  // ── Setters ──────────────────────────────────────────────────────────────

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _displayName) return;
    _displayName = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, trimmed);
  }

  Future<void> updatePhoto(String path) async {
    _photoPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhoto, path);
  }

  Future<void> removePhoto() async {
    _photoPath = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhoto);
  }
}
