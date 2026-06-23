/// Shared field validators for the auth screens. Each returns an error message
/// when the value is invalid, or null when it's fine — the same convention as
/// Flutter's FormFieldValidator, so they read naturally inline.
class Validators {
  Validators._();

  // Pragmatic email shape check: something@something.tld. Not RFC-perfect (that
  // would reject valid addresses); just catches obvious typos before we hit the
  // server.
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Enter a valid email.';
    return null;
  }

  // Matches the Supabase server-side policy (min length 8 + lowercase, uppercase
  // letters and digits) so anything the app accepts also passes the server.
  static String? password(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    if (!hasLower || !hasUpper || !hasDigit) {
      return 'Include upper- and lowercase letters and a number.';
    }
    return null;
  }

  /// Sign-in only needs a non-empty password (length rules are the server's job
  /// for existing accounts).
  static String? requiredPassword(String value) {
    if (value.isEmpty) return 'Password is required.';
    return null;
  }

  static String? confirmPassword(String value, String original) {
    if (value.isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }
}
