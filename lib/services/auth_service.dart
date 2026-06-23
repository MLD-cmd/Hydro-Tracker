import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase Auth so screens don't touch the SDK directly
/// (mirrors how the repositories isolate persistence). Keeps the rest of the app
/// free of `supabase_flutter` imports beyond this file.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// The signed-in session, or null when logged out. Set the moment the app
  /// starts because [Supabase.initialize] restores it from disk.
  Session? get currentSession => _auth.currentSession;

  bool get isSignedIn => currentSession != null;

  /// Emits on sign-in / sign-out / token refresh.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Creates an account. The display name is stored in user metadata so it's
  /// available without a separate profiles table yet. When email confirmation
  /// is enabled in the Supabase dashboard, [AuthResponse.session] comes back
  /// null and the caller should prompt the user to check their inbox.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return _auth.signUp(
      email: email.trim(),
      password: password,
      data: name == null || name.trim().isEmpty ? null : {'name': name.trim()},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
