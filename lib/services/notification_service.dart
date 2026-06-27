import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/entry_cache.dart';
import '../domain/reminder_schedule.dart';
import '../models/water_entry.dart';

/// Prefix for quick-log action ids; the amount in millilitres follows, e.g.
/// `log_250`. Encoding the amount in the id means the background isolate can
/// resolve it without reading the user's presets.
const String _quickLogActionPrefix = 'log_';

/// Handles a tapped quick-log action — on the main isolate when the app is in
/// the foreground, and on a background isolate (via [notificationTapBackground])
/// when it isn't. Appends a Water entry of the action's amount straight to the
/// SharedPreferences cache; [HydrationRepository.load] migrates it up to
/// Supabase on the next app open, so no network/auth is needed here.
Future<void> handleQuickLogResponse(NotificationResponse response) async {
  final actionId = response.actionId;
  if (actionId == null || !actionId.startsWith(_quickLogActionPrefix)) return;
  final ml = int.tryParse(actionId.substring(_quickLogActionPrefix.length));
  if (ml == null || ml <= 0) return;

  // In a background isolate the binding exists but plugins aren't registered;
  // DartPluginRegistrant wires up shared_preferences's method channel.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(kEntriesCacheKey);
  final entry = WaterEntry(
    amountMl: ml,
    timestamp: DateTime.now(),
    type: 'Water',
  );
  await prefs.setString(kEntriesCacheKey, appendCachedEntry(raw, entry));
}

/// Background-isolate entry point for quick-log action taps. Must be top-level
/// and annotated so the Dart compiler keeps it.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  handleQuickLogResponse(response);
}

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
      onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _ready = true;
  }

  /// Plain details for the one-off "reminders on" confirmation (no actions).
  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Gentle nudges to keep you sipping',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Reminder details carrying the quick-log action buttons. Each [quickLogs]
  /// entry becomes a one-tap "label + ml" action (e.g. "Glass 250ml"); tapping
  /// the notification body instead opens the app for an exact amount.
  NotificationDetails _reminderDetails(
    List<({String label, int ml})> quickLogs,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Gentle nudges to keep you sipping',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          for (final q in quickLogs)
            AndroidNotificationAction(
              '$_quickLogActionPrefix${q.ml}',
              '${q.label} ${q.ml}ml',
              showsUserInterface: false,
              cancelNotification: true,
            ),
        ],
      ),
    );
  }

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
    List<({String label, int ml})> quickLogs = const [
      (label: 'Glass', ml: 250),
      (label: 'Bottle', ml: 500),
    ],
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
    final details = _reminderDetails(quickLogs);
    var id = 100;
    for (final hour in hours) {
      await _plugin.zonedSchedule(
        id: id++,
        title: 'Time to hydrate 💧',
        body: 'Tap a glass below, or open to log something else.',
        scheduledDate: _nextInstanceOfHour(hour),
        notificationDetails: details,
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
