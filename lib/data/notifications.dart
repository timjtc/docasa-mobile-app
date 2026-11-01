import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Alert emission port — abstracted so the decision logic is unit-testable
/// without a platform channel.
abstract interface class FilterAlertPort {
  Future<void> showFilterLow(double healthPct);
}

/// Pure decision logic for the replacement alert (Plan §4.3):
/// fire while connected, at/below threshold, at most once per day.
abstract final class FilterAlertDecision {
  static const int _realertIntervalMs = 24 * 3600 * 1000;

  static bool shouldNotify({
    required double healthPct,
    required int thresholdPct,
    required int lastAlertMs,
    required int nowMs,
    required bool connected,
  }) =>
      connected &&
      healthPct <= thresholdPct &&
      nowMs - lastAlertMs >= _realertIntervalMs;
}

/// flutter_local_notifications-backed port. Initialization failures are
/// swallowed — including a denied POST_NOTIFICATIONS prompt (the request
/// happens once at first init). Tapping while the app process is alive
/// replays the in-app modal; a cold start replays via [didLaunchFromFilter].
class LocalFilterAlertPort implements FilterAlertPort {
  LocalFilterAlertPort({this.onTapped});

  /// Fired when the notification is tapped while the app process is alive —
  /// the caller opens the replacement modal (user requirement).
  final void Function()? onTapped;

  static const _payload = 'docasa_filter_alert';

  FlutterLocalNotificationsPlugin? _plugin;

  Future<FlutterLocalNotificationsPlugin> _init() async {
    if (_plugin != null) return _plugin!;
    final p = FlutterLocalNotificationsPlugin();
    await p.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse:
          onTapped != null ? (_) => onTapped!() : null,
    );
    try {
      // Android 13+ POST_NOTIFICATIONS runtime prompt (Phase 4, manifest tag).
      await p
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } on Exception {
      // Older APIs / channel quirk — notification attempt still handled below.
    }
    return _plugin = p;
  }

  /// True when the app was cold-started by tapping our notification.
  /// Errors in non-plugin environments (tests, missing platform channel) are
  /// swallowed — no cold-start replay is the safe default.
  static Future<bool> didLaunchFromFilter() async {
    try {
      final d = await FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails();
      return d?.didNotificationLaunchApp == true &&
          d?.notificationResponse?.payload == _payload;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showFilterLow(double healthPct) async {
    try {
      final p = await _init();
      await p.show(
        id: 1001,
        title: 'DOCASA filter needs replacing',
        body:
            'Filter health is at ${healthPct.round()}%. Replace the filter soon.',
        payload: _payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'docasa_filter',
            'Filter replacement alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } on Exception {
      // Uninitialized / no permission — the user sees the modal next session.
    }
  }
}

/// Inert port for tests.
class NoopFilterAlertPort implements FilterAlertPort {
  @override
  Future<void> showFilterLow(double healthPct) async {}
}
