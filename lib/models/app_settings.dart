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

  /// Absolute path to the user's chosen profile photo, or null for the initials
  /// avatar.
  final String? profilePhotoPath;

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
  );
}
