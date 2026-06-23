import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_schedule.dart';

/// Wraps flutter_local_notifications to deliver the hydration reminders the
/// Settings toggles control. Reminders fire daily at waking hours; "Quiet
/// Hours" trims the early-morning and late-evening slots.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'hydration_reminders';
  static const _channelName = 'Hydration Reminders';

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the device timezone can't be resolved.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    _ready = true;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Gentle nudges to keep you sipping',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> _ensurePermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  /// Applies the current reminder settings: schedules (or cancels) reminders
  /// and posts an immediate confirmation when first turned on.
  Future<void> applyReminders({
    required bool enabled,
    required bool quietHours,
    int startHour = 8,
    int endHour = 20,
    int intervalHours = 2,
  }) async {
    await init();
    await _plugin.cancelAll();
    if (!enabled) return;

    await _ensurePermission();

    // Immediate confirmation so the user sees it took effect.
    await _plugin.show(
      id: 0,
      title: 'Hydration Reminders on 💧',
      body: "I'll nudge you to sip throughout the day. Stay fresh!",
      notificationDetails: _details,
    );

    // Daily reminders generated from the user's chosen window + spacing; Quiet
    // Hours narrows the window to mid-day.
    final hours = reminderHours(
      startHour: startHour,
      endHour: endHour,
      intervalHours: intervalHours,
      quietHours: quietHours,
    );
    var id = 100;
    for (final hour in hours) {
      await _plugin.zonedSchedule(
        id: id++,
        title: 'Time to hydrate 💧',
        body: 'Take a sip and keep your streak going!',
        scheduledDate: _nextInstanceOfHour(hour),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    }
  }

  tz.TZDateTime _nextInstanceOfHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
