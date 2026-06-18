import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A labelled, neomorphic "well" input field used across the auth screens.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscurable = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscurable;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscurable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTheme.labelBold),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: const [
              // Soft inset-like shadow for the "sunken well" feel.
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: Offset(-3, -3),
              ),
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 8,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: _obscured,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            style: AppTheme.bodyMd.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTheme.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              suffixIcon: widget.obscurable
                  ? IconButton(
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
