import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_level.dart';
import '../models/app_settings.dart';

/// Reads/writes the signed-in user's row in the Supabase `profiles` table and
/// maps it to/from [AppSettings]. This is what makes settings (name, goal,
/// theme…) belong to the account rather than the device.
///
/// The profile photo is stored in the public `avatars` Storage bucket and its
/// URL kept in `profiles.avatar_url`. [AppSettings.profilePhotoPath] remains the
/// device-local copy for instant/offline display.
class ProfileRepository {
  static const _avatarBucket = 'avatars';

  SupabaseClient get _db => Supabase.instance.client;

  /// The current user's profile as [AppSettings], or null when signed out / the
  /// row is missing / the network is unavailable (caller falls back to local).
  Future<AppSettings?> fetch() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    try {
      final row = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return null;
      return _fromRow(row);
    } catch (_) {
      return null; // offline / transient error — caller uses local settings
    }
  }

  /// Updates the current user's profile row. No-op when signed out; swallows
  /// network errors so a failed cloud save never blocks the local save.
  ///
  /// Uses UPDATE (not upsert): the row is always created by the `handle_new_user`
  /// trigger on sign-up, and `profiles` intentionally has no INSERT RLS policy —
  /// an upsert's insert path would be rejected and silently lost.
  Future<void> save(AppSettings s) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      await _db.from('profiles').update({
        'name': s.userName,
        'base_goal_ml': s.baseGoalMl,
        'smart_goal': s.smartGoal,
        'theme_index': s.themeIndex,
        'reminders': s.reminders,
        'quiet_hours': s.quietHours,
        'weather_city': s.weatherCity,
        'onboarded': s.onboarded,
        'avatar_url': s.avatarUrl,
        'weight_kg': s.weightKg,
        'activity_level': s.activityLevel.key,
        'reminder_start_hour': s.reminderStartHour,
        'reminder_end_hour': s.reminderEndHour,
        'reminder_interval_hours': s.reminderIntervalHours,
      }).eq('id', user.id);
    } catch (_) {
      // Best-effort; local save in SettingsRepository remains the fallback.
    }
  }

  /// Uploads [file] to the user's folder in the `avatars` bucket and returns its
  /// public URL (to store in `avatar_url`), or null when signed out / on error.
  ///
  /// The filename is randomised so the public URL isn't guessable, and any
  /// previous avatars in the user's folder are deleted so files don't pile up.
  Future<String?> uploadAvatar(File file) async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    try {
      final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
      final rand = Random().nextInt(1 << 32).toRadixString(16);
      final name = '${DateTime.now().millisecondsSinceEpoch}_$rand.$ext';
      final path = '${user.id}/$name';
      final storage = _db.storage.from(_avatarBucket);

      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Remove older avatars so the user keeps just the current one.
      final existing = await storage.list(path: user.id);
      final stale = existing
          .where((f) => f.name != name)
          .map((f) => '${user.id}/${f.name}')
          .toList();
      if (stale.isNotEmpty) await storage.remove(stale);

      return storage.getPublicUrl(path);
    } catch (_) {
      return null; // offline / transient — caller keeps the local photo
    }
  }

  /// Deletes all of the user's avatars from Storage. Best-effort.
  Future<void> removeAvatar() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      final storage = _db.storage.from(_avatarBucket);
      final existing = await storage.list(path: user.id);
      if (existing.isEmpty) return;
      await storage.remove(
        existing.map((f) => '${user.id}/${f.name}').toList(),
      );
    } catch (_) {
      // best-effort
    }
  }

  AppSettings _fromRow(Map<String, dynamic> r) => AppSettings(
    userName: (r['name'] as String?) ?? 'Lilo Pelekai',
    baseGoalMl: (r['base_goal_ml'] as int?) ?? 2500,
    smartGoal: (r['smart_goal'] as bool?) ?? false,
    themeIndex: (r['theme_index'] as int?) ?? 0,
    reminders: (r['reminders'] as bool?) ?? true,
    quietHours: (r['quiet_hours'] as bool?) ?? false,
    weatherCity: (r['weather_city'] as String?) ?? 'Manila',
    onboarded: (r['onboarded'] as bool?) ?? false,
    avatarUrl: r['avatar_url'] as String?,
    weightKg: (r['weight_kg'] as num?)?.toDouble(),
    activityLevel: activityLevelFromKey(r['activity_level'] as String?),
    reminderStartHour: (r['reminder_start_hour'] as int?) ?? 8,
    reminderEndHour: (r['reminder_end_hour'] as int?) ?? 20,
    reminderIntervalHours: (r['reminder_interval_hours'] as int?) ?? 2,
  );
}
