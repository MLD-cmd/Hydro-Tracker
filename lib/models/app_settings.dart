/// User-tunable app settings, persisted on the device.
class AppSettings {
  const AppSettings({
    this.baseGoalMl = 2500,
    this.smartGoal = false,
    this.themeIndex = 0,
    this.reminders = true,
    this.quietHours = false,
    this.userName = 'Lilo Pelekai',
  });

  /// The goal the user set by hand. The *effective* goal may be higher when
  /// [smartGoal] is on and it's a hot day (see WeatherService).
  final int baseGoalMl;
  final bool smartGoal;
  final int themeIndex; // 0 Shoreline, 1 Lagoon, 2 Hibiscus
  final bool reminders;
  final bool quietHours;
  final String userName;

  AppSettings copyWith({
    int? baseGoalMl,
    bool? smartGoal,
    int? themeIndex,
    bool? reminders,
    bool? quietHours,
    String? userName,
  }) {
    return AppSettings(
      baseGoalMl: baseGoalMl ?? this.baseGoalMl,
      smartGoal: smartGoal ?? this.smartGoal,
      themeIndex: themeIndex ?? this.themeIndex,
      reminders: reminders ?? this.reminders,
      quietHours: quietHours ?? this.quietHours,
      userName: userName ?? this.userName,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseGoalMl': baseGoalMl,
    'smartGoal': smartGoal,
    'themeIndex': themeIndex,
    'reminders': reminders,
    'quietHours': quietHours,
    'userName': userName,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    baseGoalMl: (json['baseGoalMl'] as int?) ?? 2500,
    smartGoal: (json['smartGoal'] as bool?) ?? false,
    themeIndex: (json['themeIndex'] as int?) ?? 0,
    reminders: (json['reminders'] as bool?) ?? true,
    quietHours: (json['quietHours'] as bool?) ?? false,
    userName: (json['userName'] as String?) ?? 'Lilo Pelekai',
  );
}
