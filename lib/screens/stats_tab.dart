import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';
import '../services/hydration_repository.dart';
import '../widgets/soft_card.dart';

/// Analytics tab — "Hydration Tides". Shows the real last-7-days chart,
/// headline stats and milestones. Falls back to a friendly empty state until
/// the first drink is logged.
class StatsTab extends StatelessWidget {
  const StatsTab({
    super.key,
    required this.currentMl,
    required this.targetMl,
    required this.weeklyTotals,
    required this.streak,
    required this.stats,
    required this.onLogWater,
  });

  final int currentMl;
  final int targetMl;
  final List<DayTotal> weeklyTotals;
  final int streak;
  final HydrationStats stats;
  final VoidCallback onLogWater;

  String _formatLitres(int ml) {
    final litres = ml / 1000;
    return '${litres.toStringAsFixed(litres % 1 == 0 ? 0 : 1)}L';
  }

  @override
  Widget build(BuildContext context) {
    final weekTotal = weeklyTotals.fold(0, (s, d) => s + d.totalMl);
    final hasData = weekTotal > 0;
    final daysWithData = weeklyTotals.where((d) => d.totalMl > 0).length;
    final avgMl = daysWithData == 0 ? 0 : (weekTotal / daysWithData).round();
    final completion = ((currentMl / targetMl) * 100).clamp(0, 999).round();
    final daysGoalMet = weeklyTotals.where((d) => d.totalMl >= targetMl).length;

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
          const SizedBox(height: 4),
          Text('Hydration Tides', style: AppTheme.headlineLg),
          const SizedBox(height: 8),
          Text('Your weekly flow and fluid patterns.', style: AppTheme.bodyMd),
          const SizedBox(height: 24),
          if (hasData)
            _WeeklyChartCard(weeklyTotals: weeklyTotals, targetMl: targetMl)
          else
            _HeroCard(hasData: false, onLogWater: onLogWater),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.secondaryAccent,
                  label: 'Average Intake',
                  value: _formatLitres(avgMl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.hibiscus,
                  label: 'Goal Completion',
                  value: '$completion%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Recent Milestones',
            style: AppTheme.headlineLg.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MilestoneCard(
                  icon: Icons.local_fire_department_rounded,
                  iconBg: const Color(0xFFD9F5EE),
                  iconColor: AppColors.secondaryAccent,
                  title: 'Hydration Streak',
                  subtitle: streak == 1 ? '1 Day' : '$streak Days',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MilestoneCard(
                  icon: Icons.check_rounded,
                  iconBg: const Color(0xFFE6E9FB),
                  iconColor: AppColors.primary,
                  title: 'Daily Target Met',
                  subtitle: '$daysGoalMet/7 this week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: AppTheme.headlineLg.copyWith(fontSize: 18),
              ),
              Text(
                '${kAchievements.where((a) => a.isUnlocked(stats)).length}'
                '/${kAchievements.length} unlocked',
                style: AppTheme.bodyMd.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AchievementsGrid(stats: stats),
          const SizedBox(height: 28),
          const _HydrationHack(),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.weeklyTotals, required this.targetMl});

  final List<DayTotal> weeklyTotals;
  final int targetMl;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _dayLetter(DateTime d) => _dayLetters[d.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final maxDay = weeklyTotals.fold(
      0,
      (m, d) => d.totalMl > m ? d.totalMl : m,
    );
    // Scale so both the tallest bar and the goal line fit comfortably.
    final maxScale = (maxDay > targetMl ? maxDay : targetMl) * 1.15;
    const chartHeight = 150.0;
    final goalFrac = (targetMl / maxScale).clamp(0.0, 1.0);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 Days',
                style: AppTheme.labelBold.copyWith(fontSize: 15),
              ),
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 0,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.hibiscus, width: 2),
                      ),
                    ),
                  ),
                  Text('Goal', style: AppTheme.bodyMd.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                // Goal line.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: goalFrac * chartHeight,
                  child: Container(
                    height: 1.5,
                    color: AppColors.hibiscus.withValues(alpha: 0.5),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < weeklyTotals.length; i++)
                      Expanded(
                        child: _Bar(
                          fraction: maxScale == 0
                              ? 0
                              : (weeklyTotals[i].totalMl / maxScale).clamp(
                                  0.0,
                                  1.0,
                                ),
                          maxHeight: chartHeight,
                          isToday: i == weeklyTotals.length - 1,
                          metGoal: weeklyTotals[i].totalMl >= targetMl,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in weeklyTotals)
                Expanded(
                  child: Text(
                    _dayLetter(d.day),
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMd.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.maxHeight,
    required this.isToday,
    required this.metGoal,
  });

  final double fraction;
  final double maxHeight;
  final bool isToday;
  final bool metGoal;

  @override
  Widget build(BuildContext context) {
    final color = metGoal
        ? AppColors.secondaryAccent
        : AppColors.turquoise.withValues(alpha: isToday ? 0.9 : 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Container(
              height: (value * maxHeight).clamp(3.0, maxHeight),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hasData, required this.onLogWater});

  final bool hasData;
  final VoidCallback onLogWater;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFD9F5EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.liquor_rounded,
              color: AppColors.secondaryAccent,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasData ? 'Rising Tides' : 'Still Waters…',
            style: AppTheme.headlineLg.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(
            hasData
                ? 'Your hydration waves are building. Keep sipping to ride the tide!'
                : "You haven't logged any water yet. Log your first drink to start seeing your hydration waves!",
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd,
          ),
          const SizedBox(height: 20),
          _LogWaterButton(onTap: onLogWater),
        ],
      ),
    );
  }
}

class _LogWaterButton extends StatelessWidget {
  const _LogWaterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryAccent,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      shadowColor: AppColors.secondaryAccent.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Text(
            'LOG WATER',
            style: AppTheme.button.copyWith(fontSize: 14, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.headlineLg.copyWith(fontSize: 24)),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.labelBold.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.stats});

  final HydrationStats stats;

  @override
  Widget build(BuildContext context) {
    // Lay the badges out two per row, mirroring the milestone cards above.
    final rows = <Widget>[];
    for (var i = 0; i < kAchievements.length; i += 2) {
      final left = kAchievements[i];
      final right = i + 1 < kAchievements.length ? kAchievements[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _BadgeCard(achievement: left, stats: stats)),
                const SizedBox(width: 14),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : _BadgeCard(achievement: right, stats: stats),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.achievement, required this.stats});

  final Achievement achievement;
  final HydrationStats stats;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked(stats);
    final current = achievement.current(stats);
    final color = achievement.color;
    final progressText = unlocked
        ? 'Unlocked'
        : '$current/${achievement.target}${achievement.unit}';

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: unlocked
                      ? color.withValues(alpha: 0.15)
                      : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.icon,
                  size: 26,
                  color: unlocked
                      ? color
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ),
              if (unlocked)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: AppTheme.labelBold.copyWith(
              fontSize: 13,
              color: unlocked ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: achievement.progress(stats),
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation(
                unlocked ? AppColors.secondaryAccent : color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            progressText,
            style: AppTheme.labelBold.copyWith(
              fontSize: 11,
              color: unlocked ? AppColors.secondaryAccent : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationHack extends StatelessWidget {
  const _HydrationHack();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.secondaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydration Hack',
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Drinking water consistently through the day mimics your '
                  'natural biological rhythms and keeps your energy levels '
                  'high throughout the afternoon!',
                  style: AppTheme.bodyMd.copyWith(
                    fontSize: 13,
                    color: AppColors.onSurface,
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
