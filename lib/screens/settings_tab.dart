import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/activity_level.dart';
import '../models/app_settings.dart';
import '../models/bottle_preset.dart';
import '../models/drink_type.dart';
import '../domain/goal_calculator.dart';
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
    required this.onManageDrinks,
    required this.onManagePresets,
    required this.onLogout,
    required this.onRefresh,
  });

  final AppSettings settings;
  final IslandWeather weather;
  final int goalBump;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onOpenHistory;
  final VoidCallback onManageDrinks;
  final VoidCallback onManagePresets;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;

  String _litres(int ml) => '${(ml / 1000).toStringAsFixed(1)}L';

  Future<void> _openEditProfile(BuildContext context) async {
    final result = await showModalBottomSheet<_ProfileEdit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        initialName: settings.userName,
        photoPath: settings.profilePhotoPath,
        avatarUrl: settings.avatarUrl,
      ),
    );
    if (result == null) return;
    // Three cases: removed → clear photo + cloud avatar; a newly picked file →
    // set the local path (dashboard uploads it); otherwise just the name (leave
    // the photo untouched, so editing the name never wipes a cloud-only avatar).
    if (result.removed) {
      onSettingsChanged(
        settings.copyWith(userName: result.name, removePhoto: true),
      );
    } else if (result.photoPath != null) {
      onSettingsChanged(
        settings.copyWith(
          userName: result.name,
          profilePhotoPath: result.photoPath,
        ),
      );
    } else {
      onSettingsChanged(settings.copyWith(userName: result.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGoal =
        settings.baseGoalMl + (settings.smartGoal ? goalBump : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.secondaryAccent,
      child: SingleChildScrollView(
        key: const PageStorageKey('settings_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
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
            avatarUrl: settings.avatarUrl,
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
          _PersonalizedGoalCard(
            weightKg: settings.weightKg,
            activity: settings.activityLevel,
            currentGoalMl: settings.baseGoalMl,
            onChanged: (weightKg, activity) => onSettingsChanged(
              settings.copyWith(weightKg: weightKg, activityLevel: activity),
            ),
            onUseRecommended: (goalMl) =>
                onSettingsChanged(settings.copyWith(baseGoalMl: goalMl)),
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
                if (settings.reminders) ...[
                  const Divider(height: 1, indent: 56),
                  _ReminderScheduleRow(
                    icon: Icons.wb_twilight_rounded,
                    label: 'Start',
                    hour: settings.reminderStartHour,
                    onChanged: (h) => onSettingsChanged(
                      settings.copyWith(reminderStartHour: h),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ReminderScheduleRow(
                    icon: Icons.bedtime_rounded,
                    label: 'End',
                    hour: settings.reminderEndHour,
                    onChanged: (h) => onSettingsChanged(
                      settings.copyWith(reminderEndHour: h),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ReminderIntervalRow(
                    intervalHours: settings.reminderIntervalHours,
                    onChanged: (i) => onSettingsChanged(
                      settings.copyWith(reminderIntervalHours: i),
                    ),
                  ),
                ],
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
          const SizedBox(height: 12),
          SoftCard(
            onTap: onManageDrinks,
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
                    Icons.local_cafe_rounded,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Manage Drinks',
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
          const SizedBox(height: 12),
          SoftCard(
            onTap: onManagePresets,
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
                    Icons.straighten_rounded,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Quick-Log Presets',
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
      ),
    );
  }
}

/// Renders a profile photo with graceful fallback: the on-device file first
/// (instant, works offline), then the cloud [avatarUrl] (e.g. on a fresh
/// device), then the [initials] placeholder.
class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.photoPath,
    required this.avatarUrl,
    required this.initials,
    required this.size,
    required this.fontSize,
  });

  final String? photoPath;
  final String? avatarUrl;
  final String initials;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final initialsWidget = Text(
      initials,
      style: AppTheme.headlineLg.copyWith(
        fontSize: fontSize,
        color: AppColors.onPrimary,
      ),
    );

    if (photoPath != null && File(photoPath!).existsSync()) {
      return Image.file(
        File(photoPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Fall back to initials if the URL fails to load (offline / deleted).
        errorBuilder: (_, e, s) => initialsWidget,
      );
    }
    return initialsWidget;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.photoPath,
    required this.avatarUrl,
    required this.dailyGoal,
    required this.onEdit,
  });

  final String name;
  final String? photoPath;
  final String? avatarUrl;
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
                    child: _AvatarContent(
                      photoPath: photoPath,
                      avatarUrl: avatarUrl,
                      initials: _initials,
                      size: 88,
                      fontSize: 30,
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

/// The result returned by [_EditProfileSheet]: the new name, a newly picked
/// photo path (null = unchanged), and whether the photo was explicitly removed.
class _ProfileEdit {
  const _ProfileEdit({
    required this.name,
    required this.photoPath,
    required this.removed,
  });

  final String name;
  final String? photoPath;
  final bool removed;
}

/// A bottom sheet for editing the profile: tap the avatar to pick a photo from
/// the gallery, edit the display name, then save.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.initialName,
    required this.photoPath,
    required this.avatarUrl,
  });

  final String initialName;
  final String? photoPath;
  final String? avatarUrl;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  String? _photoPath;
  // Set when the user taps "Remove photo" — distinguishes "no change" from an
  // explicit removal (which must also clear the cloud avatar).
  bool _removed = false;

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
        if (mounted) {
          setState(() {
            _photoPath = dest;
            _removed = false;
          });
        }
      }
    } catch (_) {
      // Picker cancelled or failed — nothing to do.
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A photo is shown if there's a local file or a cloud avatar that wasn't
    // just removed — drives the avatar art and the "Remove photo" affordance.
    final hasLocal = _photoPath != null && File(_photoPath!).existsSync();
    final hasCloud = !_removed &&
        widget.avatarUrl != null &&
        widget.avatarUrl!.isNotEmpty;
    final hasPhoto = hasLocal || hasCloud;
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
                          : _AvatarContent(
                              photoPath: hasLocal ? _photoPath : null,
                              avatarUrl: hasCloud ? widget.avatarUrl : null,
                              initials: _initials,
                              size: 100,
                              fontSize: 34,
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
                onPressed: () => setState(() {
                  _photoPath = null;
                  _removed = true;
                }),
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
                        removed: _removed,
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

/// Lets the user enter weight + activity to get a recommended daily goal, then
/// apply it to [baseGoalMl] with one tap. The manual stepper above stays the
/// source of truth — this only *suggests* a value (recommend-and-override).
class _PersonalizedGoalCard extends StatelessWidget {
  const _PersonalizedGoalCard({
    required this.weightKg,
    required this.activity,
    required this.currentGoalMl,
    required this.onChanged,
    required this.onUseRecommended,
  });

  final double? weightKg;
  final ActivityLevel activity;
  final int currentGoalMl;
  final void Function(double? weightKg, ActivityLevel activity) onChanged;
  final ValueChanged<int> onUseRecommended;

  @override
  Widget build(BuildContext context) {
    final hasWeight = weightKg != null && weightKg! > 0;
    final recommended = hasWeight
        ? recommendedGoalMl(weightKg: weightKg!, activity: activity)
        : null;

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalized goal',
            style: AppTheme.labelBold.copyWith(
              fontSize: 15,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'From your weight and activity',
            style: AppTheme.bodyMd.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: hasWeight
                ? weightKg!.toStringAsFixed(weightKg! % 1 == 0 ? 0 : 1)
                : '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Weight (kg)',
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (raw) {
              final parsed = double.tryParse(raw.trim());
              onChanged(parsed, activity);
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in ActivityLevel.values)
                ChoiceChip(
                  label: Text(level.label),
                  selected: level == activity,
                  showCheckmark: false,
                  onSelected: (_) => onChanged(weightKg, level),
                  labelStyle: AppTheme.labelBold.copyWith(
                    fontSize: 12,
                    color: level == activity
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                  ),
                  backgroundColor: AppColors.surfaceContainer,
                  selectedColor: AppColors.secondaryAccent,
                  side: BorderSide.none,
                ),
            ],
          ),
          if (recommended != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recommended: ${(recommended / 1000).toStringAsFixed(1)}L',
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: recommended == currentGoalMl
                      ? null
                      : () => onUseRecommended(recommended),
                  child: Text(
                    recommended == currentGoalMl ? 'In use' : 'Use this',
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 13,
                      color: recommended == currentGoalMl
                          ? AppColors.onSurfaceVariant
                          : AppColors.secondaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A row that picks a whole-hour value (0–23) for the reminder window.
class _ReminderScheduleRow extends StatelessWidget {
  const _ReminderScheduleRow({
    required this.icon,
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  String _fmt(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:00 $period';
  }

  Future<void> _pickHour(BuildContext context) async {
    // A proper time picker (whole hours only) replaces the long 24-item menu.
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: 0),
      helpText: 'Select $label time',
      builder: (context, child) => MediaQuery(
        // Force the 12-hour clock dial; reminders are scheduled on the hour.
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked.hour);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _SettingLeadingIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTheme.labelBold.copyWith(
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickHour(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _fmt(hour),
                style: AppTheme.labelBold.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 40×40 rounded leading icon used by the notification setting rows, so
/// Start / End / Every line up with the toggle rows above them.
class _SettingLeadingIcon extends StatelessWidget {
  const _SettingLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: AppColors.primaryContainer),
    );
  }
}

/// A row that picks how often (every N hours) reminders fire.
class _ReminderIntervalRow extends StatelessWidget {
  const _ReminderIntervalRow({
    required this.intervalHours,
    required this.onChanged,
  });

  final int intervalHours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const _SettingLeadingIcon(icon: Icons.repeat_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Every',
              style: AppTheme.labelBold.copyWith(
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
          ),
          PopupMenuButton<int>(
            initialValue: intervalHours,
            onSelected: onChanged,
            position: PopupMenuPosition.under,
            color: AppColors.white,
            itemBuilder: (context) => [
              for (final n in const [1, 2, 3, 4])
                PopupMenuItem<int>(
                  value: n,
                  child: Text(n == 1 ? '1 hour' : '$n hours'),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                intervalHours == 1 ? '1 hour' : '$intervalHours hours',
                style: AppTheme.labelBold.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple screen listing the user's custom drinks with an add form and a
/// delete action per row. Built-in drinks are shown as non-deletable.
class ManageDrinksScreen extends StatefulWidget {
  const ManageDrinksScreen({
    super.key,
    required this.custom,
    required this.onAdd,
    required this.onDelete,
  });

  final List<DrinkType> custom;
  final Future<DrinkType?> Function(
    String name,
    double hydration,
    String iconKey,
    String colorHex,
  ) onAdd;
  final Future<void> Function(DrinkType drink) onDelete;

  @override
  State<ManageDrinksScreen> createState() => _ManageDrinksScreenState();
}

class _ManageDrinksScreenState extends State<ManageDrinksScreen> {
  late final List<DrinkType> _custom = [...widget.custom];

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<DrinkType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddDrinkSheet(onAdd: widget.onAdd),
    );
    if (added != null && mounted) setState(() => _custom.add(added));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Drinks')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.secondaryAccent,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Built-in', style: AppTheme.labelBold),
          const SizedBox(height: 8),
          for (final t in kDrinkTypes)
            ListTile(
              leading: Icon(t.icon, color: t.color),
              title: Text(t.name),
              subtitle: Text('Hydration ${(t.hydration * 100).round()}%'),
            ),
          const SizedBox(height: 16),
          Text('Your drinks', style: AppTheme.labelBold),
          const SizedBox(height: 8),
          if (_custom.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No custom drinks yet. Tap + to add one.'),
            ),
          for (final t in _custom)
            ListTile(
              leading: Icon(t.icon, color: t.color),
              title: Text(t.name),
              subtitle: Text('Hydration ${(t.hydration * 100).round()}%'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  await widget.onDelete(t);
                  if (mounted) setState(() => _custom.remove(t));
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet to create a custom drink: name, hydration weight, icon, colour.
class _AddDrinkSheet extends StatefulWidget {
  const _AddDrinkSheet({required this.onAdd});

  final Future<DrinkType?> Function(
    String name,
    double hydration,
    String iconKey,
    String colorHex,
  ) onAdd;

  @override
  State<_AddDrinkSheet> createState() => _AddDrinkSheetState();
}

class _AddDrinkSheetState extends State<_AddDrinkSheet> {
  final TextEditingController _name = TextEditingController();
  double _hydration = 1.0;
  String _iconKey = drinkIconKeys.first;
  // A small fixed palette of hex options.
  static const List<String> _palette = [
    '4FC3F7', 'FF8A65', 'FFD54F', '81C784', 'BA68C8', 'F06292',
  ];
  String _colorHex = _palette.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final created = await widget.onAdd(name, _hydration, _iconKey, _colorHex);
    if (mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New drink', style: AppTheme.headlineLg.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 20),
          Text('Hydration: ${(_hydration * 100).round()}%',
              style: AppTheme.bodyMd),
          Slider(
            value: _hydration,
            min: 0,
            max: 1.2,
            divisions: 12,
            label: '${(_hydration * 100).round()}%',
            onChanged: (v) => setState(() => _hydration = v),
          ),
          const SizedBox(height: 12),
          Text('Icon', style: AppTheme.bodyMd),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final key in drinkIconKeys)
                ChoiceChip(
                  label: Icon(iconForKey(key), size: 20),
                  selected: key == _iconKey,
                  onSelected: (_) => setState(() => _iconKey = key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Colour', style: AppTheme.bodyMd),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final hex in _palette)
                GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(0xFF000000 | int.parse(hex, radix: 16)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hex == _colorHex
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Add drink'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Manage user-defined quick-log presets. Mirrors [ManageDrinksScreen]: a
/// read-only "Built-in" list plus the user's custom presets with delete.
class ManagePresetsScreen extends StatefulWidget {
  const ManagePresetsScreen({
    super.key,
    required this.custom,
    required this.onAdd,
    required this.onDelete,
  });

  final List<BottlePreset> custom;
  final Future<BottlePreset?> Function(
    String label,
    int amountMl,
    String iconKey,
  ) onAdd;
  final Future<void> Function(BottlePreset preset) onDelete;

  @override
  State<ManagePresetsScreen> createState() => _ManagePresetsScreenState();
}

class _ManagePresetsScreenState extends State<ManagePresetsScreen> {
  late final List<BottlePreset> _custom = [...widget.custom];

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<BottlePreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddPresetSheet(onAdd: widget.onAdd),
    );
    if (added != null && mounted) setState(() => _custom.add(added));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick-Log Presets')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.secondaryAccent,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Built-in', style: AppTheme.labelBold),
          const SizedBox(height: 8),
          for (final p in kBottlePresets)
            ListTile(
              leading: Icon(p.icon, color: AppColors.secondaryAccent),
              title: Text(p.label),
              subtitle: Text('${p.amountMl}ml'),
            ),
          const SizedBox(height: 16),
          Text('Your presets', style: AppTheme.labelBold),
          const SizedBox(height: 8),
          if (_custom.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No custom presets yet. Tap + to add one.'),
            ),
          for (final p in _custom)
            ListTile(
              leading: Icon(p.icon, color: AppColors.secondaryAccent),
              title: Text(p.label),
              subtitle: Text('${p.amountMl}ml'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  await widget.onDelete(p);
                  if (mounted) setState(() => _custom.remove(p));
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet to create a custom preset: label, amount, icon.
class _AddPresetSheet extends StatefulWidget {
  const _AddPresetSheet({required this.onAdd});

  final Future<BottlePreset?> Function(
    String label,
    int amountMl,
    String iconKey,
  ) onAdd;

  @override
  State<_AddPresetSheet> createState() => _AddPresetSheetState();
}

class _AddPresetSheetState extends State<_AddPresetSheet> {
  static const int _min = 10;
  static const int _max = 5000;

  final TextEditingController _label = TextEditingController();
  final TextEditingController _amount = TextEditingController(text: '500');
  String _iconKey = drinkIconKeys.first;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (label.isEmpty || amount < _min || _saving) return;
    setState(() => _saving = true);
    final created =
        await widget.onAdd(label, amount.clamp(_min, _max), _iconKey);
    if (mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New preset', style: AppTheme.headlineLg.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. Nalgene',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              suffixText: 'ml',
            ),
          ),
          const SizedBox(height: 20),
          Text('Icon', style: AppTheme.bodyMd),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final key in drinkIconKeys)
                ChoiceChip(
                  label: Icon(iconForKey(key), size: 20),
                  selected: key == _iconKey,
                  onSelected: (_) => setState(() => _iconKey = key),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Add preset'),
            ),
          ),
        ],
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
