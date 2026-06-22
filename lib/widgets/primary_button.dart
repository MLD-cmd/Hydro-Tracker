import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Solid deep-ocean call-to-action button with a trailing arrow. Shows a
/// spinner and ignores taps while [loading] is true.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: loading ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : onPressed,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: AppTheme.button),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
