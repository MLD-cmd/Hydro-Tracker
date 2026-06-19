import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

/// Settings tab — profile, notification preferences, environment theme picker
/// and logout. State is local only (no backend yet); the theme picker is a
/// visual selection and doesn't recolour the app yet.
class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.userName,
    required this.dailyGoalLitres,
    required this.onLogout,
  });

  final String userName;
  final String dailyGoalLitres;
  final VoidCallback onLogout;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _hydrationReminders = true;
  bool _quietHours = false;
  int _themeIndex = 0; // 0 Shoreline, 1 Midnight, 2 Hibiscus

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            name: widget.userName,
            dailyGoal: widget.dailyGoalLitres,
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
                  value: _hydrationReminders,
                  onChanged: (v) => setState(() => _hydrationReminders = v),
                ),
                const Divider(height: 1, indent: 56),
                _SettingToggleRow(
                  icon: Icons.nightlight_round,
                  title: 'Island Quiet Hours',
                  subtitle: 'Pause alerts during sunset',
                  value: _quietHours,
                  onChanged: (v) => setState(() => _quietHours = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('ENVIRONMENT THEME'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _themes.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: _ThemeSwatch(
                    theme: _themes[i],
                    selected: _themeIndex == i,
                    onTap: () => setState(() => _themeIndex = i),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          _LogoutCard(onTap: widget.onLogout),
        ],
      ),
    );
  }
}

const _themes = <_ThemeOption>[
  _ThemeOption(
    label: 'Shoreline',
    colors: [Color(0xFFD9F5EE), Color(0xFF8FE3D6)],
    showDot: false,
  ),
  _ThemeOption(
    label: 'Midnight',
    colors: [Color(0xFF0B2A45), Color(0xFF061525)],
    showDot: true,
  ),
  _ThemeOption(
    label: 'Hibiscus',
    colors: [Color(0xFFE0466F), Color(0xFF7E2038)],
    showDot: false,
  ),
];

class _ThemeOption {
  const _ThemeOption({
    required this.label,
    required this.colors,
    required this.showDot,
  });

  final String label;
  final List<Color> colors;
  final bool showDot;
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

  final _ThemeOption theme;
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
                    colors: theme.colors,
                  ),
                ),
                child: theme.showDot
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
