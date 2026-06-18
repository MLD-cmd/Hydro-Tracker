import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/soft_card.dart';
import '../widgets/water_circle.dart';

/// Top-level shell holding the bottom navigation and the three tabs.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  // Hydration state (local only — no backend yet).
  int _currentMl = 1300;
  final int _targetMl = 2500;
  String _lastIntakeLabel = '45m ago';
  String _lastIntakeDetail = '250ml Still Water';

  void _logWater(int amount) {
    setState(() {
      _currentMl += amount;
      _lastIntakeLabel = 'Just now';
      _lastIntakeDetail = '${amount}ml Still Water';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _HomeTab(
              currentMl: _currentMl,
              targetMl: _targetMl,
              lastIntakeLabel: _lastIntakeLabel,
              lastIntakeDetail: _lastIntakeDetail,
              onLog: _logWater,
            ),
            const _PlaceholderTab(
              title: 'Stats',
              icon: Icons.bar_chart_rounded,
            ),
            const _PlaceholderTab(
              title: 'Settings',
              icon: Icons.settings_rounded,
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
    required this.currentMl,
    required this.targetMl,
    required this.lastIntakeLabel,
    required this.lastIntakeDetail,
    required this.onLog,
  });

  final int currentMl;
  final int targetMl;
  final String lastIntakeLabel;
  final String lastIntakeDetail;
  final ValueChanged<int> onLog;

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
          Center(
            child: WaterCircle(
              currentMl: currentMl,
              targetMl: targetMl,
              size: 290,
            ),
          ),
          const SizedBox(height: 32),
          Row(
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
                  value: '12 days',
                  detail: 'Level 4 Oasis',
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickLogCard(
                  amount: 250,
                  bubbleColor: const Color(0xFFE6E9FB),
                  iconColor: AppColors.primary,
                  onTap: () => onLog(250),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickLogCard(
                  amount: 500,
                  bubbleColor: const Color(0xFFD9F5EE),
                  iconColor: AppColors.secondaryAccent,
                  onTap: () => onLog(500),
                ),
              ),
            ],
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
          const SizedBox(height: 4),
          Text(detail, style: AppTheme.bodyMd.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  const _QuickLogCard({
    required this.amount,
    required this.bubbleColor,
    required this.iconColor,
    required this.onTap,
  });

  final int amount;
  final Color bubbleColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bubbleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop_rounded, color: iconColor, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            '+${amount}ml',
            style: AppTheme.headlineLg.copyWith(
              fontSize: 22,
              color: AppColors.onSurface,
            ),
          ),
        ],
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('$title coming soon', style: AppTheme.bodyMd),
        ],
      ),
    );
  }
}
