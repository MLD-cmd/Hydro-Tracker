import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/weather_service.dart';
import '../state/environment_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

/// Settings tab — profile, daily goal (editable + smart), notification
/// preferences, environment theme picker, history and logout. All state is
/// persisted through [onSettingsChanged]; nothing here is local-only anymore.
class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.settings,
    required this.weather,
    required this.goalBump,
    required this.onSettingsChanged,
    required this.onOpenHistory,
    required this.onLogout,
  });

  final AppSettings settings;
  final IslandWeather weather;
  final int goalBump;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onOpenHistory;
  final VoidCallback onLogout;

  String _litres(int ml) => '${(ml / 1000).toStringAsFixed(1)}L';

  @override
  Widget build(BuildContext context) {
    final effectiveGoal =
        settings.baseGoalMl + (settings.smartGoal ? goalBump : 0);

    return SingleChildScrollView(
      key: const PageStorageKey('settings_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'HydroTracker',
              style: AppTheme.headlineLg.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 8),
          _ProfileCard(
            name: settings.userName,
            dailyGoal: _litres(settings.baseGoalMl),
          ),
          const SizedBox(height: 28),
          _SectionLabel('DAILY GOAL'),
          const SizedBox(height: 12),
          _GoalCard(
            goalMl: settings.baseGoalMl,
            onChanged: (ml) =>
                onSettingsChanged(settings.copyWith(baseGoalMl: ml)),
          ),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _SettingToggleRow(
              icon: Icons.wb_sunny_rounded,
              title: 'Smart Goal',
              subtitle: settings.smartGoal && goalBump > 0
                  ? "${weather.tempC}°C today → ${_litres(effectiveGoal)} goal"
                  : 'Raise the goal on hot island days',
              value: settings.smartGoal,
              onChanged: (v) =>
                  onSettingsChanged(settings.copyWith(smartGoal: v)),
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('NOTIFICATIONS'),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _SettingToggleRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Hydration Reminders',
                  subtitle: 'Gentle nudges to keep sipping',
                  value: settings.reminders,
                  onChanged: (v) =>
                      onSettingsChanged(settings.copyWith(reminders: v)),
                ),
                const Divider(height: 1, indent: 56),
                _SettingToggleRow(
                  icon: Icons.nightlight_round,
                  title: 'Island Quiet Hours',
                  subtitle: 'Pause alerts from 10pm to 7am',
                  value: settings.quietHours,
                  onChanged: (v) =>
                      onSettingsChanged(settings.copyWith(quietHours: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('ENVIRONMENT THEME'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < kEnvironmentThemes.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: _ThemeSwatch(
                    theme: kEnvironmentThemes[i],
                    selected: settings.themeIndex == i,
                    onTap: () =>
                        onSettingsChanged(settings.copyWith(themeIndex: i)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          _SectionLabel('DATA'),
          const SizedBox(height: 12),
          SoftCard(
            onTap: onOpenHistory,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Hydration Log',
                    style: AppTheme.labelBold.copyWith(fontSize: 15),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _LogoutCard(onTap: onLogout),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.dailyGoal});

  final String name;
  final String dailyGoal;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: AppTheme.headlineLg.copyWith(
                        fontSize: 30,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(name, style: AppTheme.headlineLg.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              'DAILY GOAL: $dailyGoal',
              style: AppTheme.labelBold.copyWith(
                fontSize: 12,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stepper card for the base daily goal (1.0L–5.0L in 100ml steps).
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goalMl, required this.onChanged});

  final int goalMl;
  final ValueChanged<int> onChanged;

  static const _min = 1000;
  static const _max = 5000;
  static const _step = 100;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: goalMl > _min,
            onTap: () => onChanged((goalMl - _step).clamp(_min, _max)),
          ),
          Column(
            children: [
              Text(
                '${(goalMl / 1000).toStringAsFixed(goalMl % 1000 == 0 ? 0 : 1)}L',
                style: AppTheme.headlineLg.copyWith(fontSize: 26),
              ),
              Text(
                '$goalMl ml per day',
                style: AppTheme.bodyMd.copyWith(fontSize: 12),
              ),
            ],
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: goalMl < _max,
            onTap: () => onChanged((goalMl + _step).clamp(_min, _max)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.secondaryAccent
          : AppColors.outlineVariant.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppTheme.labelBold.copyWith(
          fontSize: 12,
          letterSpacing: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  const _SettingToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.bodyMd.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.secondaryAccent,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final EnvironmentTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.turquoise : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.swatch,
                  ),
                ),
                child: theme.showMoon
                    ? const Align(
                        alignment: Alignment(0.5, -0.5),
                        child: _Dot(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme.label,
              style: AppTheme.labelBold.copyWith(
                fontSize: 12,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, size: 20, color: AppColors.hibiscus),
          const SizedBox(width: 10),
          Text(
            'Logout from Oasis',
            style: AppTheme.labelBold.copyWith(
              fontSize: 15,
              color: AppColors.hibiscus,
            ),
          ),
        ],
      ),
    );
  }
}
