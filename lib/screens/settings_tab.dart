import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> _openEditProfile(BuildContext context) async {
    final result = await showModalBottomSheet<_ProfileEdit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        initialName: settings.userName,
        photoPath: settings.profilePhotoPath,
      ),
    );
    if (result == null) return;
    onSettingsChanged(
      settings.copyWith(
        userName: result.name,
        profilePhotoPath: result.photoPath,
        removePhoto: result.photoPath == null,
      ),
    );
  }

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
            photoPath: settings.profilePhotoPath,
            dailyGoal: _litres(settings.baseGoalMl),
            onEdit: () => _openEditProfile(context),
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
            child: Column(
              children: [
                _SettingToggleRow(
                  icon: Icons.wb_sunny_rounded,
                  title: 'Smart Goal',
                  subtitle: settings.smartGoal && goalBump > 0
                      ? "${weather.tempC}°C in ${weather.place} → ${_litres(effectiveGoal)} goal"
                      : 'Raise the goal on hot island days',
                  value: settings.smartGoal,
                  onChanged: (v) =>
                      onSettingsChanged(settings.copyWith(smartGoal: v)),
                ),
                const Divider(height: 1, indent: 56),
                _CityRow(
                  city: settings.weatherCity,
                  live: weather.isLive,
                  onChanged: (c) =>
                      onSettingsChanged(settings.copyWith(weatherCity: c)),
                ),
              ],
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
  const _ProfileCard({
    required this.name,
    required this.photoPath,
    required this.dailyGoal,
    required this.onEdit,
  });

  final String name;
  final String? photoPath;
  final String dailyGoal;
  final VoidCallback onEdit;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    return SizedBox(
      width: double.infinity,
      child: SoftCard(
        onTap: onEdit,
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
                    clipBehavior: Clip.antiAlias,
                    child: hasPhoto
                        ? Image.file(
                            File(photoPath!),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          )
                        : Text(
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

/// The result returned by [_EditProfileSheet]: the new name and photo path
/// (null means "no photo / removed").
class _ProfileEdit {
  const _ProfileEdit({required this.name, required this.photoPath});

  final String name;
  final String? photoPath;
}

/// A bottom sheet for editing the profile: tap the avatar to pick a photo from
/// the gallery, edit the display name, then save.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.initialName, required this.photoPath});

  final String initialName;
  final String? photoPath;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  String? _photoPath;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _name.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 85,
      );
      if (file != null) {
        // Copy into the app's documents dir so the path survives restarts.
        final dir = await getApplicationDocumentsDirectory();
        final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
        final dest =
            '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(file.path).copy(dest);
        if (mounted) setState(() => _photoPath = dest);
      }
    } catch (_) {
      // Picker cancelled or failed — nothing to do.
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 18),
            Text('Edit Profile', style: AppTheme.headlineLg.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickPhoto,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: _picking
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.onPrimary),
                            )
                          : hasPhoto
                              ? Image.file(
                                  File(_photoPath!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Text(
                                  _initials,
                                  style: AppTheme.headlineLg.copyWith(
                                    fontSize: 34,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (hasPhoto)
              TextButton(
                onPressed: () => setState(() => _photoPath = null),
                child: Text(
                  'Remove photo',
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 13,
                    color: AppColors.hibiscus,
                  ),
                ),
              )
            else
              Text(
                'Tap to add a photo',
                style: AppTheme.bodyMd.copyWith(fontSize: 12),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Display name',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.secondaryAccent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final name = _name.text.trim();
                    Navigator.of(context).pop(
                      _ProfileEdit(
                        name: name.isEmpty ? widget.initialName : name,
                        photoPath: _photoPath,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Save',
                      textAlign: TextAlign.center,
                      style: AppTheme.button.copyWith(fontSize: 15),
                    ),
                  ),
                ),
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

/// City picker for the Smart Goal's live weather. A simple dropdown of PH
/// cities; "Live"/"Offline" tells the user whether the temperature shown is
/// from the real API or the offline fallback.
class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.live,
    required this.onChanged,
  });

  final String city;
  final bool live;
  final ValueChanged<String> onChanged;

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
            child: const Icon(
              Icons.place_rounded,
              size: 20,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  live ? 'Live temperature' : 'Offline estimate',
                  style: AppTheme.bodyMd.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          // A compact menu anchored right under the pill, instead of the default
          // DropdownButton overlay — which expanded into a large floating list
          // that covered the screen and didn't read as a dropdown.
          PopupMenuButton<String>(
            initialValue: city,
            onSelected: onChanged,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            color: AppColors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) => [
              for (final c in kPhCities)
                PopupMenuItem<String>(
                  value: c.name,
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: AppTheme.labelBold.copyWith(
                            fontSize: 14,
                            color: c.name == city
                                ? AppColors.secondaryAccent
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (c.name == city)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.secondaryAccent,
                        ),
                    ],
                  ),
                ),
            ],
            // The visible control: city name + a dropdown arrow in a soft pill.
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city,
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 22,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
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
