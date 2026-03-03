import 'package:flutter/material.dart';
import '../services/database_helper.dart';

/// Holds the list of saved/favourite campaigns. Synced with SQLite.
class SavedCampaignsNotifier extends ChangeNotifier {
  List<Map<String, dynamic>> _list = [];

  SavedCampaignsNotifier() {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final rows = await DatabaseHelper.instance.getAllSavedCampaigns();
    _list = List<Map<String, dynamic>>.from(rows.map((r) => Map<String, dynamic>.from(r)));
    notifyListeners();
  }

  List<Map<String, dynamic>> get list => List.unmodifiable(_list);

  bool isSaved(String title) =>
      _list.any((c) => (c['title'] as String?) == title);

  Future<void> add(Map<String, dynamic> campaign) async {
    final title = campaign['title'] as String?;
    if (title == null || isSaved(title)) return;
    
    // Convert to a properly typed map to store
    final dataValues = {
      'title': campaign['title'],
      'description': campaign['description'],
      'raised': campaign['raised'],
      'target': campaign['target'],
      'progress': campaign['progress'],
      'imagePath': campaign['imagePath'],
      'category': campaign['category'],
    };

    _list.add(Map<String, dynamic>.from(dataValues));
    notifyListeners();
    
    await DatabaseHelper.instance.insertSavedCampaign(dataValues);
  }

  Future<void> remove(String title) async {
    _list.removeWhere((c) => (c['title'] as String?) == title);
    notifyListeners();
    
    await DatabaseHelper.instance.deleteSavedCampaign(title);
  }

  void toggle(Map<String, dynamic> campaign) {
    final title = campaign['title'] as String?;
    if (title == null) return;
    if (isSaved(title)) {
      remove(title);
    } else {
      add(campaign);
    }
  }
}

/// Provides [SavedCampaignsNotifier] to the widget tree (above Navigator so routes can access it).
/// Uses a fallback so [of] never returns null.
class SavedNotifierProvider extends InheritedNotifier<SavedCampaignsNotifier> {
  const SavedNotifierProvider({
    super.key,
    required SavedCampaignsNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SavedCampaignsNotifier? _fallback;

  static void setFallback(SavedCampaignsNotifier notifier) {
    _fallback = notifier;
  }

  /// Returns the notifier **and** registers a rebuild dependency.
  static SavedCampaignsNotifier of(BuildContext context) {
    final notifier = context
        .dependOnInheritedWidgetOfExactType<SavedNotifierProvider>()
        ?.notifier;
    return notifier ?? _fallback!;
  }

  /// Returns the notifier **without** registering a rebuild dependency.
  /// Use this in `didChangeDependencies` or `build` methods that only need a
  /// reference and already manage their own listener lifecycle.
  static SavedCampaignsNotifier read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<SavedNotifierProvider>();
    final notifier = (element?.widget as SavedNotifierProvider?)?.notifier;
    return notifier ?? _fallback!;
  }
}
