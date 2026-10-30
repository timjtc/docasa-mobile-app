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
/// swallowed — the Android 13+ POST_NOTIFICATIONS runtime permission flow is
/// wired in Phase 4 (Development-Process §7 task 1 sibling).
class LocalFilterAlertPort implements FilterAlertPort {
  LocalFilterAlertPort();

  FlutterLocalNotificationsPlugin? _plugin;

  Future<FlutterLocalNotificationsPlugin> _init() async {
    if (_plugin != null) return _plugin!;
    final p = FlutterLocalNotificationsPlugin();
    await p.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    return _plugin = p;
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
      // Not initialized / no permission — Phase 4 concern.
    }
  }
}

/// Inert port for tests.
class NoopFilterAlertPort implements FilterAlertPort {
  @override
  Future<void> showFilterLow(double healthPct) async {}
}
