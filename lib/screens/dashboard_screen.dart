import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';
import '../models/app_settings.dart';
import '../models/drink_type.dart';
import '../services/auth_service.dart';
import '../domain/drink_catalog.dart';
import '../repositories/drink_type_repository.dart';
import '../domain/hydration_forecast.dart';
import '../repositories/hydration_repository.dart';
import '../services/notification_service.dart';
import '../domain/preset_catalog.dart';
import '../repositories/preset_repository.dart';
import '../domain/streak.dart';
import '../repositories/profile_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/weather_service.dart';
import '../state/environment_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hydration_buddy.dart';
import '../widgets/soft_card.dart';
import '../widgets/water_circle.dart';
import 'history_screen.dart';
import 'sign_in_screen.dart';
import 'stats_tab.dart';
import 'settings_tab.dart';

/// Top-level shell holding the bottom navigation and the three tabs.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  // Hydration data and settings are persisted on the device (no backend yet).
  final HydrationRepository _repo = HydrationRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final DrinkTypeRepository _drinkRepo = DrinkTypeRepository();
  final PresetRepository _presetRepo = PresetRepository();
  DrinkCatalog _catalog = const DrinkCatalog();
  PresetCatalog _presetCatalog = const PresetCatalog();
  static const WeatherService _weather = WeatherService();

  AppSettings _settings = const AppSettings();
  // Starts as the instant offline simulation, then is replaced by the live
  // temperature for the chosen city once the network responds (see
  // [_refreshWeather]).
  IslandWeather _todayWeather = _weather.simulated();
  DrinkType _selectedType = kDrinkTypes.first;
  bool _loading = true;

  // Backs the "Logged …" snackbar's auto-dismiss. We close it ourselves rather
  // than leaning on SnackBar.duration: the snackbar appears the moment the log
  // sheet pops, and that overlapping animation can stop Flutter's built-in
  // auto-hide timer from ever starting (leaving it stuck until UNDO).
  Timer? _snackTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _snackTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_repo.load(), _settingsRepo.load()]);
    // Best-effort load of the user's custom drinks (built-ins always present).
    final custom = await _drinkRepo.fetchAll();
    if (custom != null) _catalog = DrinkCatalog(custom: custom);
    // Likewise the user's custom quick-log presets (built-ins always present).
    final presets = await _presetRepo.fetchAll();
    if (presets != null) _presetCatalog = PresetCatalog(custom: presets);
    var settings = _settingsRepo.settings;
    // Prefer the signed-in user's cloud profile (real name, goal, theme…) over
    // the local defaults. Falls back to local when offline / signed out.
    final cloud = await _profileRepo.fetch();
    if (cloud != null) {
      settings = cloud.copyWith(
        // onboarding is a per-device UX flag — don't let a fresh cloud row
        // (onboarded=false) re-trigger onboarding once done locally.
        onboarded: settings.onboarded || cloud.onboarded,
        // Keep the device's local photo file for instant/offline display; the
        // cloud avatarUrl (from cloud) is the fallback when there's no local
        // file (e.g. a fresh device), handled by the avatar display widgets.
        profilePhotoPath: settings.profilePhotoPath,
      );
      await _settingsRepo.save(settings); // cache locally
      await _profileRepo.save(settings); // push merged values (e.g. onboarded)
    }
    if (!mounted) return;
    environmentThemeIndex.value = settings.themeIndex;
    setState(() {
      _settings = settings;
      _loading = false;
    });
    // Sync scheduled reminders with the saved preference.
    NotificationService.instance.applyReminders(
      enabled: _settings.reminders,
      quietHours: _settings.quietHours,
      startHour: _settings.reminderStartHour,
      endHour: _settings.reminderEndHour,
      intervalHours: _settings.reminderIntervalHours,
      quickLogs: _quickLogActions,
    );
    // Replace the simulated weather with the live temperature for the saved
    // city. Fire-and-forget: the UI already has a usable value to show.
    _refreshWeather();
  }

  /// Pulls the live temperature for the saved city and updates the UI. Safe to
  /// call repeatedly; on failure [WeatherService.fetch] returns the simulation.
  Future<void> _refreshWeather() async {
    final weather = await _weather.fetch(cityByName(_settings.weatherCity));
    if (!mounted) return;
    setState(() => _todayWeather = weather);
  }

  /// Pull-to-refresh: re-read saved data and re-fetch today's live weather.
  Future<void> _refresh() async {
    await Future.wait([_repo.load(), _settingsRepo.load()]);
    if (mounted) setState(() => _settings = _settingsRepo.settings);
    await _refreshWeather();
  }

  /// A gentle nudge toward water when less-hydrating drinks (coffee, juice)
  /// out-pour water today — named after whichever leads. Null when water keeps
  /// up, and also null once the goal is met: a smashed goal celebrates rather
  /// than nags, so both the buddy and the mix-card badge stay quiet together.
  /// See [hydrationNudgeFor].
  HydrationNudge? get _nudge {
    if (_repo.todayTotal >= _effectiveGoal) return null;
    return hydrationNudgeFor(_repo.todayByType());
  }

  /// The first two presets, surfaced as the reminder's quick-log action
  /// buttons (e.g. "Glass 250ml", "Bottle 500ml").
  List<({String label, int ml})> get _quickLogActions => _presetCatalog.all
      .take(2)
      .map((p) => (label: p.label, ml: p.amountMl))
      .toList();

  /// The goal in effect today: the base goal, nudged up on hot days when the
  /// smart goal is enabled.
  int get _effectiveGoal {
    final base = _settings.baseGoalMl;
    if (!_settings.smartGoal) return base;
    return base + _weather.goalBumpMl(_todayWeather);
  }

  Future<void> _logWater(int amount, DrinkType type) async {
    final goal = _effectiveGoal;
    final before = _repo.todayTotal;
    // Which badges were already earned before this drink, so we can spot the
    // ones this drink unlocks.
    final unlockedBefore = _unlockedAchievementIds(goal);
    await _repo.addEntry(amount, type: type.name);
    final after = _repo.todayTotal;
    final newlyUnlocked = kAchievements
        .where((a) =>
            a.isUnlocked(_repo.statsFor(goal)) && !unlockedBefore.contains(a.id))
        .toList();
    if (!mounted) return;
    // Remember the chosen drink so the log card and next sheet default to it.
    setState(() => _selectedType = type);

    _showUndoSnackBar(amount, type);

    // Celebrate the moment the day's total first crosses the goal, then announce
    // any badges that drink earned. Awaited so they appear one at a time rather
    // than stacking on top of each other.
    if (before < goal && after >= goal) {
      await showGoalCelebration(
        context,
        streak: _repo.currentStreak(goal),
        goalMl: goal,
      );
    }
    for (final achievement in newlyUnlocked) {
      if (!mounted) break;
      await showAchievementCelebration(context, achievement: achievement);
    }
  }

  /// The ids of every achievement currently unlocked for [goal].
  Set<String> _unlockedAchievementIds(int goal) {
    final stats = _repo.statsFor(goal);
    return {
      for (final a in kAchievements)
        if (a.isUnlocked(stats)) a.id,
    };
  }

  void _showUndoSnackBar(int amount, DrinkType type) {
    const visibleFor = Duration(seconds: 3);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Logged ${amount}ml ${type.name}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: visibleFor,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.turquoise,
          onPressed: () async {
            await _repo.removeLast();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    // Belt-and-braces auto-dismiss (see [_snackTimer]). hideCurrentSnackBar is
    // a no-op if it's already gone — e.g. the user tapped UNDO — so this is
    // safe even when the built-in timer did fire.
    _snackTimer?.cancel();
    _snackTimer = Timer(visibleFor, messenger.hideCurrentSnackBar);
  }

  Future<void> _updateSettings(AppSettings next) async {
    final remindersChanged =
        next.reminders != _settings.reminders ||
        next.quietHours != _settings.quietHours ||
        next.reminderStartHour != _settings.reminderStartHour ||
        next.reminderEndHour != _settings.reminderEndHour ||
        next.reminderIntervalHours != _settings.reminderIntervalHours;
    final cityChanged = next.weatherCity != _settings.weatherCity;

    // When the photo changed, sync it to Storage: upload a newly picked file and
    // capture its URL, or clear the cloud avatar when the photo was removed.
    var toSave = next;
    if (next.profilePhotoPath != _settings.profilePhotoPath) {
      if (next.profilePhotoPath != null) {
        final url = await _profileRepo.uploadAvatar(
          File(next.profilePhotoPath!),
        );
        if (url != null) toSave = next.copyWith(avatarUrl: url);
      } else {
        await _profileRepo.removeAvatar();
        toSave = next.copyWith(removePhoto: true); // also clears avatarUrl
      }
    }

    await _settingsRepo.save(toSave);
    // Mirror the change to the user's cloud profile (best-effort).
    await _profileRepo.save(toSave);
    environmentThemeIndex.value = toSave.themeIndex;
    if (mounted) setState(() => _settings = toSave);
    if (remindersChanged) {
      NotificationService.instance.applyReminders(
        enabled: next.reminders,
        quietHours: next.quietHours,
        startHour: next.reminderStartHour,
        endHour: next.reminderEndHour,
        intervalHours: next.reminderIntervalHours,
        quickLogs: _quickLogActions,
      );
    }
    // Picking a new city re-pulls the live temperature for that place.
    if (cityChanged) _refreshWeather();
  }

  Future<void> _openManageDrinks() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageDrinksScreen(
          custom: _catalog.custom,
          onAdd: (name, hydration, iconKey, colorHex) async {
            final created = await _drinkRepo.insert(
              name: name,
              hydration: hydration,
              iconKey: iconKey,
              colorHex: colorHex,
            );
            if (created != null) {
              setState(() {
                _catalog = DrinkCatalog(custom: [..._catalog.custom, created]);
              });
            }
            return created;
          },
          onDelete: (drink) async {
            if (drink.id != null) await _drinkRepo.delete(drink.id!);
            setState(() {
              _catalog = DrinkCatalog(
                custom:
                    _catalog.custom.where((d) => d.id != drink.id).toList(),
              );
            });
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openManagePresets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManagePresetsScreen(
          custom: _presetCatalog.custom,
          onAdd: (label, amountMl, iconKey) async {
            final created = await _presetRepo.insert(
              label: label,
              amountMl: amountMl,
              iconKey: iconKey,
            );
            if (created != null) {
              setState(() {
                _presetCatalog =
                    PresetCatalog(custom: [..._presetCatalog.custom, created]);
              });
            }
            return created;
          },
          onDelete: (preset) async {
            if (preset.id != null) await _presetRepo.delete(preset.id!);
            setState(() {
              _presetCatalog = PresetCatalog(
                custom: _presetCatalog.custom
                    .where((p) => p.id != preset.id)
                    .toList(),
              );
            });
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          repo: _repo,
          goalMl: _effectiveGoal,
          catalog: _catalog,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  String get _lastIntakeLabel {
    final last = _repo.lastEntry;
    if (last == null) return 'No drinks yet';
    return _relativeTime(last.timestamp);
  }

  String get _lastIntakeDetail {
    final last = _repo.lastEntry;
    if (last == null) return 'Tap a quick log below';
    return '${last.amountMl}ml ${last.type}';
  }

  /// Short relative time like "Just now", "45m ago", "3h ago", "2d ago".
  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    // Clear cached logs so the next account on a shared device starts clean.
    await _repo.clear();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: GradientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final goal = _effectiveGoal;
    final streak = _repo.streakStatus(goal);
    final forecast = forecastHydration(
      currentMl: _repo.todayTotal,
      goalMl: goal,
      now: DateTime.now(),
      dayStartHour: _settings.reminderStartHour,
      dayEndHour: _settings.reminderEndHour,
    );
    return Scaffold(
      // The bottom nav floats with rounded top corners; tint the Scaffold with
      // the gradient's bottom colour so those corners reveal the gradient
      // rather than the bare window (which showed as a dark/green sliver).
      backgroundColor: activeEnvironmentTheme.gradient.last,
      body: GradientBackground(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _HomeTab(
              catalog: _catalog,
              presetCatalog: _presetCatalog,
              currentMl: _repo.todayTotal,
              targetMl: goal,
              smartGoalActive: _settings.smartGoal,
              weather: _todayWeather,
              goalBump: _weather.goalBumpMl(_todayWeather),
              lastIntakeLabel: _lastIntakeLabel,
              lastIntakeDetail: _lastIntakeDetail,
              streak: streak,
              forecast: forecast,
              selectedType: _selectedType,
              byType: _repo.todayByType(),
              nudge: _nudge,
              onLog: _logWater,
              onRefresh: _refresh,
            ),
            StatsTab(
              currentMl: _repo.todayTotal,
              targetMl: goal,
              weeklyTotals: _repo.last7Days(),
              monthlyTotals: _repo.lastNDays(30),
              todayEntries: _repo.todayEntries(),
              hourlyTotals: _repo.todayByHour(),
              streak: _repo.currentStreak(goal),
              stats: _repo.statsFor(goal),
              onLogWater: () => setState(() => _tabIndex = 0),
              onRefresh: _refresh,
            ),
            SettingsTab(
              settings: _settings,
              weather: _todayWeather,
              goalBump: _weather.goalBumpMl(_todayWeather),
              onSettingsChanged: _updateSettings,
              onOpenHistory: _openHistory,
              onManageDrinks: _openManageDrinks,
              onManagePresets: _openManagePresets,
              onLogout: _logout,
              onRefresh: _refresh,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.catalog,
    required this.presetCatalog,
    required this.currentMl,
    required this.targetMl,
    required this.smartGoalActive,
    required this.weather,
    required this.goalBump,
    required this.lastIntakeLabel,
    required this.lastIntakeDetail,
    required this.streak,
    required this.forecast,
    required this.selectedType,
    required this.byType,
    required this.nudge,
    required this.onLog,
    required this.onRefresh,
  });

  final DrinkCatalog catalog;
  final PresetCatalog presetCatalog;
  final int currentMl;
  final int targetMl;
  final bool smartGoalActive;
  final IslandWeather weather;
  final int goalBump;
  final String lastIntakeLabel;
  final String lastIntakeDetail;
  final StreakStatus streak;
  final HydrationForecast forecast;
  final DrinkType selectedType;

  /// Raw millilitres logged today, grouped by drink-type name.
  final Map<String, int> byType;
  final HydrationNudge? nudge;
  final void Function(int amount, DrinkType type) onLog;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.secondaryAccent,
      child: SingleChildScrollView(
        key: const PageStorageKey('home_scroll'),
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
          const SizedBox(height: 4),
          HydrationBuddy(
            currentMl: currentMl,
            targetMl: targetMl,
            nudge: nudge,
            tempC: weather.tempC,
            tempLabel: weather.label,
            place: weather.place,
            streak: streak.count,
            mix: byType,
          ),
          if (smartGoalActive) ...[
            const SizedBox(height: 12),
            _WeatherBanner(weather: weather, goalBump: goalBump),
          ],
          const SizedBox(height: 20),
          Center(
            child: WaterCircle(
              currentMl: currentMl,
              targetMl: targetMl,
              size: 290,
            ),
          ),
          const SizedBox(height: 32),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.history_rounded,
                    iconColor: AppColors.primaryContainer,
                    title: 'Last Intake',
                    value: lastIntakeLabel,
                    detail: lastIntakeDetail,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.hibiscus,
                    title: 'Daily Streak',
                    value: streak.count == 1 ? '1 day' : '${streak.count} days',
                    detail: streak.count == 0
                        ? 'Hit your goal today!'
                        : streak.metToday
                            ? 'Keep it going!'
                            : "Don't break it today!",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ForecastCard(forecast: forecast),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'QUICK LOG',
              style: AppTheme.labelBold.copyWith(
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _CustomLogCard(
            catalog: catalog,
            presetCatalog: presetCatalog,
            initialType: selectedType,
            onLog: onLog,
          ),
          if (byType.isNotEmpty) ...[
            const SizedBox(height: 24),
            _DrinkMixCard(catalog: catalog, byType: byType, nudge: nudge),
          ],
        ],
        ),
      ),
    );
  }
}

/// "Today's Mix" — a vertical share bar per drink logged today, each filling to
/// its percent of the day's raw volume and reusing that drink's colour. Drinks
/// with nothing logged are hidden so the card never looks empty. Pairs with the
/// buddy's coffee-vs-water nudge: when the warning shows, you can see coffee's
/// bar standing taller than water's.
class _DrinkMixCard extends StatelessWidget {
  const _DrinkMixCard({
    required this.catalog,
    required this.byType,
    required this.nudge,
  });

  final DrinkCatalog catalog;
  final Map<String, int> byType;
  final HydrationNudge? nudge;

  @override
  Widget build(BuildContext context) {
    final total = byType.values.fold(0, (sum, v) => sum + v);
    final shown =
        catalog.all.where((t) => (byType[t.name] ?? 0) > 0).toList();

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Mix",
                style: AppTheme.headlineLg.copyWith(fontSize: 17),
              ),
              const Spacer(),
              if (nudge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: nudge!.leader.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(nudge!.leader.icon, size: 13, color: nudge!.leader.color),
                      const SizedBox(width: 4),
                      Text(
                        'over water',
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 11,
                          color: nudge!.leader.color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            total == 0
                ? 'What you sip will show up here'
                : 'How much of each drink today — and its share',
            style: AppTheme.bodyMd.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final type in shown)
                Expanded(
                  child: _MixBar(
                    type: type,
                    ml: byType[type.name]!,
                    pct: total == 0 ? 0 : (byType[type.name]! / total),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MixBar extends StatelessWidget {
  const _MixBar({required this.type, required this.ml, required this.pct});

  final DrinkType type;
  final int ml; // raw millilitres of this drink today — never decreases
  final double pct; // share of the day's volume, 0..1

  @override
  Widget build(BuildContext context) {
    // Tiny shares still get a visible sliver so the bar never disappears.
    final fill = pct <= 0 ? 0.0 : pct.clamp(0.06, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 18, color: type.color),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            width: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fill),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    heightFactor: value,
                    widthFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: type.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Hero number: the real amount you drank. This never shrinks when you
          // log another drink — only the share below it shifts.
          Text(
            '$ml ml',
            style: AppTheme.labelBold.copyWith(
              fontSize: 13,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            type.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMd.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          // Demoted share — clearly a slice of the day's mix, so a shift reads
          // as "smaller slice", not "my water disappeared".
          Text(
            '${(pct * 100).round()}% of mix',
            style: AppTheme.bodyMd.copyWith(
              fontSize: 10,
              color: AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable drink-type picker. Every option is laid out as an equal-width
/// segment (icon over label) in a single row, so the control is always fully
/// visible and balanced — no horizontal scrolling, wrapping, or clipped chips.
/// The chosen type colours the quick-log cards and is what gets logged; it only
/// changes what the next tap records and never resets the day's total.
class _DrinkTypeSelector extends StatelessWidget {
  const _DrinkTypeSelector({
    required this.catalog,
    required this.selected,
    required this.onSelect,
  });

  final DrinkCatalog catalog;
  final DrinkType selected;
  final ValueChanged<DrinkType> onSelect;

  @override
  Widget build(BuildContext context) {
    final types = catalog.all;
    // Up to 5 fit as equal-width segments; beyond that, scroll horizontally so
    // custom drinks never cramp or clip the row.
    if (types.length <= 5) {
      return Row(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _DrinkSegment(
                type: types[i],
                selected: types[i].name == selected.name,
                onTap: () => onSelect(types[i]),
              ),
            ),
          ],
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: _DrinkSegment(
                type: types[i],
                selected: types[i].name == selected.name,
                onTap: () => onSelect(types[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrinkSegment extends StatelessWidget {
  const _DrinkSegment({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DrinkType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? type.color : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? type.color : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 22,
              color: selected ? AppColors.white : type.color,
            ),
            const SizedBox(height: 6),
            Text(
              type.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelBold.copyWith(
                fontSize: 11,
                color: selected ? AppColors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small weather banner shown whenever the smart goal is on, so switching
/// city always gives visible feedback. On a hot day (goal bumped) it's a warm
/// "drink more" note; on a mild day it simply confirms the goal is unchanged.
class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner({required this.weather, required this.goalBump});

  final IslandWeather weather;
  final int goalBump;

  @override
  Widget build(BuildContext context) {
    final hot = goalBump > 0;
    final extra =
        (goalBump / 1000).toStringAsFixed(goalBump % 1000 == 0 ? 0 : 1);
    final place = "${weather.tempC}°C in ${weather.place} (${weather.label})";
    final message = hot
        ? "It's $place — goal nudged up ${extra}L to keep you cool."
        : "It's $place — a comfy day, so your goal stays as set.";
    final accent = hot ? const Color(0xFFE9920B) : const Color(0xFF2E97DB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hot ? const Color(0xFFFFF1D6) : const Color(0xFFE2F1F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hot ? Icons.wb_sunny_rounded : Icons.water_drop_rounded,
            color: accent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTheme.bodyMd.copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                // A weather-appropriate, hydration-friendly drink tip.
                Text(
                  drinkSuggestionFor(weather.tempC),
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: AppTheme.bodyMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(value, style: AppTheme.headlineLg.copyWith(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail, style: AppTheme.bodyMd.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

/// "Today's Pace" — a one-line read on how the day is tracking against an even
/// spread of the goal across the user's active hours, plus a projected finish
/// time when on/ahead of pace. Turns the static ring into a forward-looking
/// nudge: "drink a bit now" vs "you're cruising, goal by 6:40 PM".
class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});

  final HydrationForecast forecast;

  /// 12-hour clock like "6:40 PM" for the projected finish.
  static String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final finish = f.projectedFinish;
    final byLabel =
        finish == null ? null : 'on this pace, goal by ${_clock(finish)}';

    final IconData icon;
    final Color color;
    final String title;
    final String detail;
    switch (f.status) {
      case PaceStatus.met:
        icon = Icons.check_circle_rounded;
        color = AppColors.primary;
        title = 'Goal reached';
        detail = "You're all set for today — nice work!";
      case PaceStatus.ahead:
        icon = Icons.trending_up_rounded;
        color = AppColors.secondaryAccent;
        title = 'Ahead of pace';
        detail = '${f.paceDeltaMl.abs()}ml ahead'
            '${byLabel == null ? '' : ' — $byLabel'}';
      case PaceStatus.onTrack:
        icon = Icons.timeline_rounded;
        color = AppColors.secondaryAccent;
        title = 'On track';
        detail = byLabel ?? '${f.remainingMl}ml to go';
      case PaceStatus.behind:
        icon = Icons.trending_down_rounded;
        color = AppColors.hibiscus;
        title = 'Behind pace';
        detail = '${f.paceDeltaMl.abs()}ml behind — ${f.remainingMl}ml to go';
      case PaceStatus.notStarted:
        icon = Icons.local_drink_rounded;
        color = AppColors.onSurfaceVariant;
        title = 'No sips yet';
        detail = "${f.remainingMl}ml to reach today's goal";
    }

    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTheme.bodyMd.copyWith(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The single Quick Log action on Home. Tapping it opens the log sheet, which
/// is where you pick the drink, the amount (a preset or an exact value), and
/// confirm — keeping Home itself uncluttered.
class _CustomLogCard extends StatelessWidget {
  const _CustomLogCard({
    required this.catalog,
    required this.presetCatalog,
    required this.initialType,
    required this.onLog,
  });

  final DrinkCatalog catalog;
  final PresetCatalog presetCatalog;
  final DrinkType initialType;
  final void Function(int amount, DrinkType type) onLog;

  @override
  Widget build(BuildContext context) {
    final color = initialType.color;
    return SoftCard(
      onTap: () async {
        final result = await showModalBottomSheet<({int amount, DrinkType type})>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _CustomAmountSheet(
            catalog: catalog,
            presetCatalog: presetCatalog,
            initialType: initialType,
          ),
        );
        if (result != null) onLog(result.amount, result.type);
      },
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_drink_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log a drink',
                  style: AppTheme.headlineLg.copyWith(
                    fontSize: 19,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pick your drink & amount',
                  style: AppTheme.bodyMd.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.add_circle_rounded, color: color, size: 32),
        ],
      ),
    );
  }
}

/// The log sheet — the one place logging happens. It holds the drink-type
/// selector, the container presets, and a custom stepper/field, then pops the
/// chosen amount + drink back to the caller. Tapping a preset fills the amount
/// (which you can still fine-tune, since a real glass isn't exactly 250ml).
class _CustomAmountSheet extends StatefulWidget {
  const _CustomAmountSheet({
    required this.catalog,
    required this.presetCatalog,
    required this.initialType,
  });

  final DrinkCatalog catalog;
  final PresetCatalog presetCatalog;
  final DrinkType initialType;

  @override
  State<_CustomAmountSheet> createState() => _CustomAmountSheetState();
}

class _CustomAmountSheetState extends State<_CustomAmountSheet> {
  static const int _min = 10;
  static const int _max = 5000;

  int _amount = 250;
  late DrinkType _type = widget.initialType;
  late final TextEditingController _controller = TextEditingController(
    text: '$_amount',
  );

  void _setAmount(int value, {bool syncField = true}) {
    final clamped = value.clamp(_min, _max);
    setState(() => _amount = clamped);
    if (syncField) {
      _controller.text = '$clamped';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  void _onFieldChanged(String raw) {
    final value = int.tryParse(raw);
    // Let the field show a mid-typing value (e.g. "5" on the way to "500")
    // without snapping the cursor; submit-time clamping keeps it sane.
    if (value != null) setState(() => _amount = value.clamp(_min, _max));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, color: type.color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add ${type.name}',
                  style: AppTheme.headlineLg.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Pick the drink right here in the sheet.
            _DrinkTypeSelector(
              catalog: widget.catalog,
              selected: _type,
              onSelect: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _setAmount(_amount - 50),
                ),
                const SizedBox(width: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _controller,
                        onChanged: _onFieldChanged,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        style: AppTheme.headlineLg.copyWith(
                          fontSize: 34,
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.only(bottom: 4),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.secondaryAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'ml',
                        style: AppTheme.bodyMd.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => _setAmount(_amount + 50),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // The container presets — tap to fill the amount above.
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final preset in widget.presetCatalog.all)
                  ChoiceChip(
                    label: Text('${preset.label} · ${preset.amountMl}ml'),
                    selected: _amount == preset.amountMl,
                    onSelected: (_) => _setAmount(preset.amountMl),
                    showCheckmark: false,
                    labelStyle: AppTheme.labelBold.copyWith(
                      color: _amount == preset.amountMl
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                    backgroundColor: AppColors.surfaceContainer,
                    selectedColor: AppColors.secondaryAccent,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(
                  (amount: _amount.clamp(_min, _max), type: _type),
                ),
                child: Text(
                  'Log ${_amount.clamp(_min, _max)}ml ${type.name}',
                  style: AppTheme.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round − / + stepper button used by the custom-amount sheet.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'HOME'),
    (Icons.bar_chart_rounded, 'STATS'),
    (Icons.settings_rounded, 'SETTINGS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.secondaryAccent
        : AppColors.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.secondaryAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.labelBold.copyWith(
                fontSize: 11,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
