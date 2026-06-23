import 'package:flutter/material.dart';
import '../models/drink_type.dart';
import '../models/water_entry.dart';
import '../services/drink_catalog.dart';
import '../services/hydration_repository.dart';
import '../state/environment_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_edit_sheet.dart';
import '../widgets/gradient_background.dart';
import '../widgets/soft_card.dart';

/// History as a goal-consistency calendar: a month heatmap where each day is
/// tinted by how much of the goal it met, with month-by-month navigation across
/// the whole log. Tap a day to see that day's drinks below (and delete any).
///
/// The calendar deliberately encodes *consistency* (hit / partial / miss), not
/// volume — volume is the Stats month bar chart's job — so the two never echo
/// each other.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.repo,
    required this.goalMl,
    required this.catalog,
    required this.onChanged,
  });

  final HydrationRepository repo;

  /// The drink catalog (built-ins + custom) used to resolve each entry's icon,
  /// colour and the edit sheet's type chips.
  final DrinkCatalog catalog;

  /// The daily goal used to colour each day as met / partial / missed.
  final int goalMl;

  /// Called after an entry is deleted so the dashboard can refresh its totals.
  final VoidCallback onChanged;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  static const _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];

  late DateTime _visibleMonth; // first-of-month being shown
  late DateTime _selectedDay; // midnight of the day whose entries show below

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  Future<void> _delete(WaterEntry entry) async {
    await widget.repo.deleteEntry(entry);
    widget.onChanged();
    if (mounted) setState(() {});
  }

  Future<void> _edit(WaterEntry entry) async {
    final result = await showEntryEditSheet(
      context,
      entry: entry,
      drinkTypes: widget.catalog.all,
    );
    if (result == null) return;
    await widget.repo.updateEntry(
      entry,
      amountMl: result.amountMl,
      type: result.type,
      timestamp: result.timestamp,
    );
    widget.onChanged();
    if (mounted) setState(() {});
  }

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _selectedHeading() {
    final d = _selectedDay;
    final diff = _today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final dayEntries = widget.repo.entriesForDay(_selectedDay);
    final dayTotal = dayEntries.fold(0, (s, e) => s + e.effectiveMl);
    final metGoal = widget.goalMl > 0 && dayTotal >= widget.goalMl;

    return Scaffold(
      // Blend the status-bar/app-bar area with the gradient's top colour so the
      // bare window never shows through.
      backgroundColor: activeEnvironmentTheme.gradient.first,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        title: Text(
          'Hydration Log',
          style: AppTheme.headlineLg.copyWith(fontSize: 20),
        ),
      ),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _CalendarCard(
              visibleMonth: _visibleMonth,
              selectedDay: _selectedDay,
              today: _today,
              goalMl: widget.goalMl,
              totals: widget.repo.monthTotals(
                _visibleMonth.year,
                _visibleMonth.month,
              ),
              monthLabel: '${_months[_visibleMonth.month - 1]} '
                  '${_visibleMonth.year}',
              weekdayLetters: _weekdayLetters,
              firstEntryDate: widget.repo.firstEntryDate,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
              onSelectDay: (d) => setState(() => _selectedDay = d),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedHeading(),
                  style: AppTheme.headlineLg.copyWith(fontSize: 17),
                ),
                if (dayTotal > 0)
                  Row(
                    children: [
                      if (metGoal) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.secondaryAccent,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${(dayTotal / 1000).toStringAsFixed(1)}L',
                        style: AppTheme.labelBold.copyWith(
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (dayEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No drinks logged this day.',
                    style: AppTheme.bodyMd,
                  ),
                ),
              )
            else
              for (final e in dayEntries)
                _HistoryRow(
                  entry: e,
                  type: widget.catalog.byName(e.type),
                  time: _time(e.timestamp),
                  onEdit: () => _edit(e),
                  onDelete: () => _delete(e),
                ),
          ],
        ),
      ),
    );
  }
}

/// The month heatmap: header with ‹ › navigation, weekday letters, and a 7-wide
/// grid of day cells tinted by goal completion.
class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDay,
    required this.today,
    required this.goalMl,
    required this.totals,
    required this.monthLabel,
    required this.weekdayLetters,
    required this.firstEntryDate,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final DateTime today;
  final int goalMl;
  final Map<int, int> totals;
  final String monthLabel;
  final List<String> weekdayLetters;

  /// Earliest logged day; days before it predate tracking and so are never
  /// flagged as "missed" (you can't miss a goal before you started).
  final DateTime? firstEntryDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    // Sunday-first calendar: weekday is Mon=1..Sun=7, so Sun maps to 0.
    final leadingBlanks =
        DateTime(visibleMonth.year, visibleMonth.month, 1).weekday % 7;
    final cellCount = leadingBlanks + daysInMonth;
    final rows = (cellCount / 7).ceil();

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
              Text(
                monthLabel,
                style: AppTheme.labelBold.copyWith(fontSize: 16),
              ),
              _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in weekdayLetters)
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMd.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _buildCell(r * 7 + c - leadingBlanks, daysInMonth),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          const _Legend(),
        ],
      ),
    );
  }

  Widget _buildCell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }
    final date = DateTime(visibleMonth.year, visibleMonth.month, day);
    final total = totals[day] ?? 0;
    final isFuture = date.isAfter(today);
    // A "missed" day is a *past* day with nothing logged — but only once
    // tracking had started. Today (still in progress) and pre-tracking days
    // stay neutral, never red.
    final startedTracking =
        firstEntryDate != null && !date.isBefore(_dayOf(firstEntryDate!));
    final isMissed =
        !isFuture && date != today && total == 0 && startedTracking;
    return _DayCell(
      day: day,
      total: total,
      goalMl: goalMl,
      isToday: date == today,
      isSelected: date == selectedDay,
      isFuture: isFuture,
      isMissed: isMissed,
      onTap: () => onSelectDay(date),
    );
  }

  DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: AppColors.primary,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// A single day square. Colour tells the story: solid accent = goal met, a
/// faded accent that deepens with how close you got = partial, bare = nothing.
/// A muted coral that reads as "missed" without clashing with the warm palette.
const Color _missedRed = Color(0xFFE07A6E);

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.total,
    required this.goalMl,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.isMissed,
    required this.onTap,
  });

  final int day;
  final int total;
  final int goalMl;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final bool isMissed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = goalMl > 0 ? (total / goalMl).clamp(0.0, 1.0) : 0.0;
    final met = goalMl > 0 && total >= goalMl;

    final Color bg;
    final Color fg;
    if (met) {
      bg = AppColors.secondaryAccent;
      fg = AppColors.white;
    } else if (total > 0) {
      // Faded accent that deepens toward the goal so a near-miss reads darker.
      bg = AppColors.secondaryAccent.withValues(alpha: 0.12 + 0.33 * fraction);
      fg = AppColors.onSurface;
    } else if (isMissed) {
      // Past day, tracking had started, nothing logged — a missed goal.
      bg = _missedRed.withValues(alpha: 0.18);
      fg = _missedRed;
    } else {
      // Future or pre-tracking day: neutral, never flagged.
      bg = AppColors.onSurfaceVariant.withValues(alpha: 0.06);
      fg = isFuture
          ? AppColors.onSurfaceVariant.withValues(alpha: 0.35)
          : AppColors.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: isFuture ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : isToday
                  ? Border.all(color: AppColors.primary, width: 1.2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: AppTheme.bodyMd.copyWith(
                fontSize: 13,
                fontWeight: (met || isToday || isSelected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny key so the heatmap's tints are legible at a glance.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget swatch(Color c) => Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    final style = AppTheme.bodyMd.copyWith(fontSize: 11);

    return Row(
      children: [
        swatch(_missedRed.withValues(alpha: 0.18)),
        Text('Missed', style: style),
        const SizedBox(width: 14),
        swatch(AppColors.secondaryAccent.withValues(alpha: 0.3)),
        Text('Partial', style: style),
        const SizedBox(width: 14),
        swatch(AppColors.secondaryAccent),
        Text('Goal met', style: style),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.type,
    required this.time,
    required this.onEdit,
    required this.onDelete,
  });

  final WaterEntry entry;
  final DrinkType type;
  final String time;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: type.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.amountMl}ml ${type.name}',
                    style: AppTheme.labelBold.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(time, style: AppTheme.bodyMd.copyWith(fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
