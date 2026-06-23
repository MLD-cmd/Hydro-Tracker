import 'activity_level.dart';

/// User-tunable app settings, persisted on the device.
class AppSettings {
  const AppSettings({
    this.baseGoalMl = 2500,
    this.smartGoal = false,
    this.themeIndex = 0,
    this.reminders = true,
    this.quietHours = false,
    this.userName = 'Lilo Pelekai',
    this.weatherCity = 'Manila',
    this.onboarded = false,
    this.profilePhotoPath,
    this.avatarUrl,
    this.weightKg,
    this.activityLevel = ActivityLevel.sedentary,
    this.reminderStartHour = 8,
    this.reminderEndHour = 20,
    this.reminderIntervalHours = 2,
  });

  /// The goal the user set by hand. The *effective* goal may be higher when
  /// [smartGoal] is on and it's a hot day (see WeatherService).
  final int baseGoalMl;
  final bool smartGoal;
  final int themeIndex; // 0 Shoreline, 1 Lagoon, 2 Hibiscus
  final bool reminders;
  final bool quietHours;
  final String userName;

  /// The Philippine city used for the live Smart-Goal weather lookup.
  final String weatherCity;

  /// Whether the one-time onboarding has been completed.
  final bool onboarded;

  /// Absolute path to the user's chosen profile photo on *this device*, or null
  /// for the initials avatar. Used for instant/offline display; the canonical
  /// cross-device copy is [avatarUrl] (Supabase Storage).
  final String? profilePhotoPath;

  /// Public URL of the photo in the Supabase `avatars` bucket, or null. This is
  /// what makes the avatar follow the account to a new device, where there's no
  /// local file. Display prefers the local file when present, else this URL.
  final String? avatarUrl;

  /// Body weight in kilograms, used to suggest a personalised goal. Null until
  /// the user enters it.
  final double? weightKg;

  /// The user's activity level, feeding the personalised goal suggestion.
  final ActivityLevel activityLevel;

  /// Reminder window + spacing (whole hours, 0–23). Drive the generated
  /// notification times — see [reminderHours].
  final int reminderStartHour;
  final int reminderEndHour;
  final int reminderIntervalHours;

  AppSettings copyWith({
    int? baseGoalMl,
    bool? smartGoal,
    int? themeIndex,
    bool? reminders,
    bool? quietHours,
    String? userName,
    String? weatherCity,
    bool? onboarded,
    String? profilePhotoPath,
    String? avatarUrl,
    double? weightKg,
    ActivityLevel? activityLevel,
    int? reminderStartHour,
    int? reminderEndHour,
    int? reminderIntervalHours,
    bool removePhoto = false,
  }) {
    return AppSettings(
      baseGoalMl: baseGoalMl ?? this.baseGoalMl,
      smartGoal: smartGoal ?? this.smartGoal,
      themeIndex: themeIndex ?? this.themeIndex,
      reminders: reminders ?? this.reminders,
      quietHours: quietHours ?? this.quietHours,
      userName: userName ?? this.userName,
      weatherCity: weatherCity ?? this.weatherCity,
      onboarded: onboarded ?? this.onboarded,
      profilePhotoPath:
          removePhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      avatarUrl: removePhoto ? null : (avatarUrl ?? this.avatarUrl),
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      reminderStartHour: reminderStartHour ?? this.reminderStartHour,
      reminderEndHour: reminderEndHour ?? this.reminderEndHour,
      reminderIntervalHours:
          reminderIntervalHours ?? this.reminderIntervalHours,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseGoalMl': baseGoalMl,
    'smartGoal': smartGoal,
    'themeIndex': themeIndex,
    'reminders': reminders,
    'quietHours': quietHours,
    'userName': userName,
    'weatherCity': weatherCity,
    'onboarded': onboarded,
    'profilePhotoPath': profilePhotoPath,
    'avatarUrl': avatarUrl,
    'weightKg': weightKg,
    'activityLevel': activityLevel.key,
    'reminderStartHour': reminderStartHour,
    'reminderEndHour': reminderEndHour,
    'reminderIntervalHours': reminderIntervalHours,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    baseGoalMl: (json['baseGoalMl'] as int?) ?? 2500,
    smartGoal: (json['smartGoal'] as bool?) ?? false,
    themeIndex: (json['themeIndex'] as int?) ?? 0,
    reminders: (json['reminders'] as bool?) ?? true,
    quietHours: (json['quietHours'] as bool?) ?? false,
    userName: (json['userName'] as String?) ?? 'Lilo Pelekai',
    weatherCity: (json['weatherCity'] as String?) ?? 'Manila',
    onboarded: (json['onboarded'] as bool?) ?? false,
    profilePhotoPath: json['profilePhotoPath'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    activityLevel: activityLevelFromKey(json['activityLevel'] as String?),
    reminderStartHour: (json['reminderStartHour'] as int?) ?? 8,
    reminderEndHour: (json['reminderEndHour'] as int?) ?? 20,
    reminderIntervalHours: (json['reminderIntervalHours'] as int?) ?? 2,
  );
}
