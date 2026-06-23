import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// How strong a password is, used by the sign-up strength meter and validator.
enum PasswordStrength { empty, weak, medium, strong }

/// Scores a password on length and character variety. Deliberately simple and
/// transparent (no external lib): a point each for decent length, extra length,
/// mixed case, a digit, and a symbol — then bucketed into weak/medium/strong.
PasswordStrength estimatePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;

  var score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[A-Z]').hasMatch(password)) {
    score++;
  }
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score == 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

extension PasswordStrengthDisplay on PasswordStrength {
  String get label => switch (this) {
    PasswordStrength.empty => '',
    PasswordStrength.weak => 'Weak',
    PasswordStrength.medium => 'Medium',
    PasswordStrength.strong => 'Strong',
  };

  /// How many of the 3 meter segments to fill.
  int get filledSegments => switch (this) {
    PasswordStrength.empty => 0,
    PasswordStrength.weak => 1,
    PasswordStrength.medium => 2,
    PasswordStrength.strong => 3,
  };

  Color get color => switch (this) {
    PasswordStrength.empty => AppColors.onSurfaceVariant,
    PasswordStrength.weak => AppColors.hibiscus,
    PasswordStrength.medium => const Color(0xFFE0A23E), // amber
    PasswordStrength.strong => AppColors.secondaryAccent,
  };
}
