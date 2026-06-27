import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';
import '../models/drink_type.dart';
import '../models/water_entry.dart';
import '../repositories/hydration_repository.dart';
import '../widgets/soft_card.dart';

/// The time span the Stats screen is showing.
enum _StatsRange { today, week, month }

/// Analytics tab — "Hydration Tides". Real last-7-day / last-30-day chart with
/// a goal line, tappable bars, a range summary, headline stats, milestones,
/// achievements and a rotating tip. Falls back to a friendly empty state until
/// the first drink is logged.
class StatsTab extends StatefulWidget {
  const StatsTab({
    super.key,
    required this.currentMl,
    required this.targetMl,
    required this.weeklyTotals,
    required this.monthlyTotals,
    required this.todayEntries,
    required this.hourlyTotals,
    required this.streak,
    required this.stats,
    required this.onLogWater,
    required this.onRefresh,
  });

  final int currentMl;
  final int targetMl;
  final List<DayTotal> weeklyTotals;
  final List<DayTotal> monthlyTotals;
  final List<WaterEntry> todayEntries;
  final List<HourTotal> hourlyTotals;
  final int streak;
  final HydrationStats stats;
  final VoidCallback onLogWater;
  final Future<void> Function() onRefresh;

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  _StatsRange _rangeMode = _StatsRange.week;
  int? _selectedIndex; // tapped bar within the active range

  /// The day-bucketed list behind the Week/Month chart (unused for Today).
  List<DayTotal> get _range => _rangeMode == _StatsRange.month
      ? widget.monthlyTotals
      : widget.weeklyTotals;

  String _formatLitres(int ml) {
    final litres = ml / 1000;
    return '${litres.toStringAsFixed(litres % 1 == 0 ? 0 : 1)}L';
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final isToday = _rangeMode == _StatsRange.today;
    final hasData = widget.stats.entryCount > 0;
    // "Avg / Active Day" always reflects the rolling week in the Today view
    // (a single day has no average), and the active range otherwise.
    final avgSource = isToday ? widget.weeklyTotals : range;
    final daysWithData = avgSource.where((d) => d.totalMl > 0).length;
    final rangeTotal = avgSource.fold(0, (s, d) => s + d.totalMl);
    final avgMl = daysWithData == 0 ? 0 : (rangeTotal / daysWithData).round();
    final completion = ((widget.currentMl / widget.targetMl) * 100)
        .clamp(0, 999)
        .round();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.secondaryAccent,
      child: SingleChildScrollView(
        key: const PageStorageKey('stats_scroll'),
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
          Text('Hydration Tides', style: AppTheme.headlineLg),
          const SizedBox(height: 8),
          Text('Your hydration flow and patterns.', style: AppTheme.bodyMd),
          const SizedBox(height: 24),
          if (!hasData)
            _HeroCard(onLogWater: widget.onLogWater)
          else ...[
            _RangeToggle(
              mode: _rangeMode,
              onChanged: (m) => setState(() {
                _rangeMode = m;
                _selectedIndex = null;
              }),
            ),
            const SizedBox(height: 16),
            if (isToday) ...[
              _TodaySummary(
                totalMl: widget.currentMl,
                targetMl: widget.targetMl,
                drinkCount: widget.todayEntries.length,
                formatLitres: _formatLitres,
              ),
              const SizedBox(height: 16),
              _HourlyChartCard(
                hours: widget.hourlyTotals,
                formatLitres: _formatLitres,
              ),
              const SizedBox(height: 16),
              _TodayTimelineCard(entries: widget.todayEntries),
            ] else ...[
              _SummaryRow(
                label: _rangeMode == _StatsRange.month ? 'This Month' : 'This Week',
                range: range,
                targetMl: widget.targetMl,
                formatLitres: _formatLitres,
              ),
              const SizedBox(height: 16),
              _ChartCard(
                range: range,
                targetMl: widget.targetMl,
                monthView: _rangeMode == _StatsRange.month,
                selectedIndex: _selectedIndex,
                formatLitres: _formatLitres,
                onSelect: (i) => setState(
                  () => _selectedIndex = _selectedIndex == i ? null : i,
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.secondaryAccent,
                  label: 'Avg / Active Day',
                  value: _formatLitres(avgMl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.hibiscus,
                  label: "Today's Goal",
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
                  title: 'Current Streak',
                  subtitle: widget.streak == 1 ? '1 Day' : '${widget.streak} Days',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MilestoneCard(
                  icon: Icons.military_tech_rounded,
                  iconBg: const Color(0xFFFFE3EC),
                  iconColor: AppColors.hibiscus,
                  title: 'Personal Best',
                  subtitle: widget.stats.bestStreak == 1
                      ? '1 Day'
                      : '${widget.stats.bestStreak} Days',
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
                '${kAchievements.where((a) => a.isUnlocked(widget.stats)).length}'
                '/${kAchievements.length} unlocked',
                style: AppTheme.bodyMd.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AchievementsGrid(stats: widget.stats),
          const SizedBox(height: 28),
          const _HydrationHack(),
        ],
        ),
      ),
    );
  }
}

/// Today / Week / Month segmented toggle.
class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.mode, required this.onChanged});

  final _StatsRange mode;
  final ValueChanged<_StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _segment('Today', mode == _StatsRange.today,
              () => onChanged(_StatsRange.today)),
          _segment('Week', mode == _StatsRange.week,
              () => onChanged(_StatsRange.week)),
          _segment('Month', mode == _StatsRange.month,
              () => onChanged(_StatsRange.month)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.secondaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.labelBold.copyWith(
              fontSize: 14,
              color: active ? AppColors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// At-a-glance band: range total, best day, and days on target.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.range,
    required this.targetMl,
    required this.formatLitres,
  });

  final String label;
  final List<DayTotal> range;
  final int targetMl;
  final String Function(int) formatLitres;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final total = range.fold(0, (s, d) => s + d.totalMl);
    final onTarget = range.where((d) => d.totalMl >= targetMl).length;
    DayTotal? best;
    for (final d in range) {
      if (best == null || d.totalMl > best.totalMl) best = d;
    }
    final bestLabel = (best == null || best.totalMl == 0)
        ? '—'
        : formatLitres(best.totalMl);

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          _cell(label, formatLitres(total), 'total'),
          _divider(),
          _cell(
            'Best Day',
            bestLabel,
            best == null || best.totalMl == 0
                ? ''
                : _dayLetters[best.day.weekday - 1],
          ),
          _divider(),
          _cell('On Target', '$onTarget', 'of ${range.length} days'),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 38, color: AppColors.outlineVariant.withValues(alpha: 0.4));

  Widget _cell(String label, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.headlineLg.copyWith(fontSize: 20)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact 3-cell summary for the Today view: total so far, drinks logged, and
/// progress toward today's goal.
class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.totalMl,
    required this.targetMl,
    required this.drinkCount,
    required this.formatLitres,
  });

  final int totalMl;
  final int targetMl;
  final int drinkCount;
  final String Function(int) formatLitres;

  @override
  Widget build(BuildContext context) {
    final pct = targetMl == 0 ? 0 : ((totalMl / targetMl) * 100).round();
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          _cell('Today', formatLitres(totalMl), 'so far'),
          _divider(),
          _cell('Drinks', '$drinkCount', 'logged'),
          _divider(),
          _cell('Goal', '$pct%', 'of ${formatLitres(targetMl)}'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 38,
        color: AppColors.outlineVariant.withValues(alpha: 0.4),
      );

  Widget _cell(String label, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.headlineLg.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// The Today view's centrepiece: a connected timeline of each drink logged
/// today, earliest first, so you can see *when* you hydrate. Read-only — manage
/// or delete entries from the Hydration Log in Settings.
///
/// Past [_maxRowsBeforeScroll] drinks the list stops growing and scrolls inside
/// its own bounded area, so a busy day doesn't push the rest of the Stats page
/// far down.
class _TodayTimelineCard extends StatefulWidget {
  const _TodayTimelineCard({required this.entries});

  final List<WaterEntry> entries; // chronological, earliest first

  @override
  State<_TodayTimelineCard> createState() => _TodayTimelineCardState();
}

class _TodayTimelineCardState extends State<_TodayTimelineCard> {
  // Above this many drinks the list collapses to the first [_collapsedCount]
  // rows behind a "Show all" toggle, so a busy day doesn't push the rest of the
  // Stats page far down. Tapping expands it inline (no nested scrolling).
  static const _collapsedCount = 6;

  bool _expanded = false;

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final canCollapse = entries.length > _collapsedCount;
    final visibleCount =
        (canCollapse && !_expanded) ? _collapsedCount : entries.length;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Timeline",
            style: AppTheme.labelBold.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'When you drank through the day',
            style: AppTheme.bodyMd.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No drinks logged today yet.\n'
                  'Tap Log on the Home tab to start your timeline.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMd.copyWith(fontSize: 13),
                ),
              ),
            )
          else ...[
            for (var i = 0; i < visibleCount; i++)
              _timelineRow(
                entries[i],
                isFirst: i == 0,
                // Based on the full list: while collapsed, the last visible row
                // isn't the real last, so its connector keeps running — which
                // reads as "there's more below".
                isLast: i == entries.length - 1,
              ),
            if (canCollapse) _showToggle(visibleCount, entries.length),
          ],
        ],
      ),
    );
  }

  Widget _showToggle(int visibleCount, int total) {
    final showingAll = visibleCount >= total;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showingAll ? 'Show less' : 'Show all $total',
                style: AppTheme.labelBold.copyWith(
                  fontSize: 13,
                  color: AppColors.secondaryAccent,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                showingAll
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: AppColors.secondaryAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineRow(
    WaterEntry e, {
    required bool isFirst,
    required bool isLast,
  }) {
    final type = drinkTypeByName(e.type);
    const lineColor = Color(0xFFEADFD3); // soft sand connector
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _time(e.timestamp),
                textAlign: TextAlign.right,
                style: AppTheme.bodyMd.copyWith(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Rail: a connecting line with a coloured dot at each entry.
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 7,
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: type.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3, bottom: isLast ? 0 : 16),
              child: Row(
                children: [
                  Icon(type.icon, color: type.color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${e.amountMl}ml ${type.name}',
                      style: AppTheme.labelBold.copyWith(fontSize: 14),
                    ),
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.range,
    required this.targetMl,
    required this.monthView,
    required this.selectedIndex,
    required this.formatLitres,
    required this.onSelect,
  });

  final List<DayTotal> range;
  final int targetMl;
  final bool monthView;
  final int? selectedIndex;
  final String Function(int) formatLitres;
  final ValueChanged<int> onSelect;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  @override
  Widget build(BuildContext context) {
    final maxDay = range.fold(0, (m, d) => d.totalMl > m ? d.totalMl : m);
    final maxScale = (maxDay > targetMl ? maxDay : targetMl) * 1.15;
    const chartHeight = 150.0;
    final goalFrac = (targetMl / maxScale).clamp(0.0, 1.0);
    final barPad = monthView ? 1.5 : 5.0;

    final selected = selectedIndex != null ? range[selectedIndex!] : null;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: selected == null
                    ? Text(
                        monthView ? 'Last 30 Days' : 'Last 7 Days',
                        style: AppTheme.labelBold.copyWith(fontSize: 15),
                      )
                    : Text(
                        '${_months[selected.day.month - 1]} ${selected.day.day}'
                        ' · ${formatLitres(selected.totalMl)}'
                        ' · ${((selected.totalMl / targetMl) * 100).round()}% of goal',
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 13,
                          color: AppColors.secondaryAccent,
                        ),
                      ),
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
                    for (var i = 0; i < range.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                          child: _Bar(
                            fraction: maxScale == 0
                                ? 0
                                : (range[i].totalMl / maxScale).clamp(0.0, 1.0),
                            maxHeight: chartHeight,
                            isToday: i == range.length - 1,
                            isSelected: selectedIndex == i,
                            metGoal: range[i].totalMl >= targetMl,
                            horizontalPad: barPad,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Day letters only in week view (30 labels would be unreadable).
          if (!monthView)
            Row(
              children: [
                for (final d in range)
                  Expanded(
                    child: Text(
                      _dayLetters[d.day.weekday - 1],
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Tap a bar for that day · ${_months[range.first.day.month - 1]} '
                '${range.first.day.day} – ${_months[range.last.day.month - 1]} '
                '${range.last.day.day}',
                style: AppTheme.bodyMd.copyWith(fontSize: 11),
              ),
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
    required this.isSelected,
    required this.metGoal,
    required this.horizontalPad,
  });

  final double fraction;
  final double maxHeight;
  final bool isToday;
  final bool isSelected;
  final bool metGoal;
  final double horizontalPad;

  @override
  Widget build(BuildContext context) {
    final color = metGoal
        ? AppColors.secondaryAccent
        : AppColors.turquoise.withValues(alpha: isToday ? 0.9 : 0.55);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
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
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : isToday
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

/// Today's intake shaped across the 24 hours of the day — the *when* behind the
/// daily total. Reuses [_Bar] so it matches the week/month chart, but drops the
/// goal line (a per-hour goal is meaningless) and highlights the peak hour
/// instead. Tap any bar to read that hour's exact amount.
class _HourlyChartCard extends StatefulWidget {
  const _HourlyChartCard({required this.hours, required this.formatLitres});

  final List<HourTotal> hours;
  final String Function(int) formatLitres;

  @override
  State<_HourlyChartCard> createState() => _HourlyChartCardState();
}

class _HourlyChartCardState extends State<_HourlyChartCard> {
  int? _selected;

  // Bars carrying an axis label, and the label shown beneath each.
  static const _labelHours = {0: '12a', 6: '6a', 12: '12p', 18: '6p', 23: '11p'};

  String _hourLabel(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12 $period';
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours;
    final dayTotal = hours.fold(0, (s, h) => s + h.totalMl);
    final maxHour = hours.fold(0, (m, h) => h.totalMl > m ? h.totalMl : m);
    // Index of the busiest hour, so it can be highlighted. -1 when nothing yet.
    final peakIndex = maxHour == 0
        ? -1
        : hours.indexWhere((h) => h.totalMl == maxHour);
    final maxScale = maxHour == 0 ? 1 : maxHour * 1.15;
    const chartHeight = 130.0;

    final selected = _selected != null ? hours[_selected!] : null;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          selected != null
              ? Text(
                  '${_hourLabel(selected.hour)} · '
                  '${selected.totalMl == 0 ? 'nothing logged' : widget.formatLitres(selected.totalMl)}'
                  '${_selected == peakIndex && selected.totalMl > 0 ? ' · peak hour' : ''}',
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 13,
                    color: AppColors.secondaryAccent,
                  ),
                )
              : Text(
                  'Today by Hour',
                  style: AppTheme.labelBold.copyWith(fontSize: 15),
                ),
          const SizedBox(height: 18),
          if (dayTotal == 0)
            SizedBox(
              height: chartHeight,
              child: Center(
                child: Text(
                  'No drinks logged yet today.',
                  style: AppTheme.bodyMd.copyWith(fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < hours.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(
                          () => _selected = _selected == i ? null : i,
                        ),
                        child: _Bar(
                          fraction: (hours[i].totalMl / maxScale)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                          maxHeight: chartHeight,
                          isToday: false,
                          isSelected: _selected == i,
                          metGoal: i == peakIndex,
                          horizontalPad: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in _labelHours.values)
                Text(
                  label,
                  style: AppTheme.bodyMd.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onLogWater});

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
          Text('Still Waters…', style: AppTheme.headlineLg.copyWith(fontSize: 20)),
          const SizedBox(height: 10),
          Text(
            "You haven't logged any water yet. Log your first drink to start "
            'seeing your hydration waves!',
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

/// A hydration tip that rotates day to day so the screen feels fresh.
class _HydrationHack extends StatelessWidget {
  const _HydrationHack();

  static const _tips = [
    'Drinking water consistently through the day mimics your natural '
        'biological rhythms and keeps your energy levels high.',
    'Start your morning with a glass of water — you wake up mildly '
        'dehydrated after a night without fluids.',
    'Feeling hungry mid-afternoon? It is often thirst in disguise. Try a '
        'glass of water first.',
    'Add a slice of citrus or cucumber to make plain water more enticing '
        'and easier to finish.',
    'Keep a bottle within arm’s reach — visible water gets sipped far more '
        'often than water in the fridge.',
    'Coconut water replaces electrolytes after a hot day on the island, not '
        'just plain fluid.',
    'Pair each coffee with a glass of water to offset its mild diuretic '
        'effect and stay balanced.',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final tip = _tips[dayOfYear % _tips.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
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
                  tip,
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
