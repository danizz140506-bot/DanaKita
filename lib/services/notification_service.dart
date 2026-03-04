import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Singleton service that handles local push notifications.
///
/// Currently used for donation success confirmations. Can be extended
/// for campaign reminders, goal alerts, etc.
class NotificationService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Notification channel IDs ───────────────────────────────────────────────
  static const _donationChannel = AndroidNotificationDetails(
    'donation_channel', // channel id
    'Donation Alerts', // channel name
    channelDescription: 'Notifications for successful donations',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    styleInformation: BigTextStyleInformation(''),
  );

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once at app startup (in `main()` or equivalent).
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Request notification permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Donation Success Notification ──────────────────────────────────────────

  /// Show an instant notification after a successful donation.
  Future<void> showDonationSuccess({
    required String campaign,
    required double amount,
    String? transactionId,
  }) async {
    if (!_initialized) return;

    final body = StringBuffer();
    body.write(
        'Your donation of RM ${amount.toStringAsFixed(2)} to "$campaign" has been received. ');
    body.write('Thank you for making a difference! 💜');
    if (transactionId != null) {
      body.write('\nTransaction ID: $transactionId');
    }

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      'Donation Successful! 🎉',
      body.toString(),
      const NotificationDetails(
        android: _donationChannel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
