import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/password_strength.dart';

/// A 3-segment strength meter shown under the sign-up password field. Fills and
/// colours by [estimatePasswordStrength], with a matching label. Renders nothing
/// while the field is empty so the form stays compact.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = estimatePasswordStrength(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    final filled = strength.filledSegments;
    final color = strength.color;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 5,
                decoration: BoxDecoration(
                  color: i < filled
                      ? color
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 6),
          ],
          const SizedBox(width: 10),
          Text(
            strength.label,
            style: AppTheme.bodyMd.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
