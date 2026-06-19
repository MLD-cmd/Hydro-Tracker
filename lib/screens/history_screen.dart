import 'package:flutter/material.dart';
import '../models/drink_type.dart';
import '../models/water_entry.dart';
import '../services/hydration_repository.dart';
import '../state/environment_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/soft_card.dart';

/// A scrollable log of every drink, grouped by day, with swipe/tap to delete.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repo, required this.onChanged});

  final HydrationRepository repo;

  /// Called after an entry is deleted so the dashboard can refresh its totals.
  final VoidCallback onChanged;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _delete(WaterEntry entry) async {
    await widget.repo.deleteEntry(entry);
    widget.onChanged();
    if (mounted) setState(() {});
  }

  String _dayHeading(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
    ];
    return '${months[day.month - 1]} ${day.day}';
  }

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.repo.entriesNewestFirst;

    // Build a flat list of headers + rows grouped by calendar day.
    final items = <Widget>[];
    DateTime? lastDay;
    for (final e in entries) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      if (lastDay == null || day != lastDay) {
        final dayEntries = entries.where(
          (x) =>
              x.timestamp.year == day.year &&
              x.timestamp.month == day.month &&
              x.timestamp.day == day.day,
        );
        final dayTotal = dayEntries.fold(0, (s, x) => s + x.effectiveMl);
        items.add(
          Padding(
            padding: EdgeInsets.only(top: lastDay == null ? 0 : 22, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dayHeading(day),
                  style: AppTheme.headlineLg.copyWith(fontSize: 17),
                ),
                Text(
                  '${(dayTotal / 1000).toStringAsFixed(1)}L',
                  style: AppTheme.labelBold.copyWith(
                    color: AppColors.secondaryAccent,
                  ),
                ),
              ],
            ),
          ),
        );
        lastDay = day;
      }
      items.add(_HistoryRow(entry: e, time: _time(e.timestamp), onDelete: () => _delete(e)));
    }

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
        child: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'No drinks logged yet.\nYour history will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMd,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: items,
              ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.time,
    required this.onDelete,
  });

  final WaterEntry entry;
  final String time;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = drinkTypeByName(entry.type);
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
