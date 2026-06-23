import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_background.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/primary_button.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _creating = false;

  // Per-field inline errors. Null = no error shown.
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  // Re-validate live once the user has attempted to submit at least once.
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validate() {
    setState(() {
      _emailError = Validators.email(_emailController.text);
      _passwordError = Validators.password(_passwordController.text);
      _confirmError = Validators.confirmPassword(
        _confirmController.text,
        _passwordController.text,
      );
    });
    return _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  void _revalidateIfSubmitted() {
    if (_submitted) _validate();
  }

  // The password field always rebuilds (to drive the live strength meter), and
  // re-validates too once the user has tried to submit.
  void _onPasswordChanged(String _) {
    if (_submitted) {
      _validate();
    } else {
      setState(() {});
    }
  }

  Future<void> _createAccount() async {
    if (_creating) return;
    setState(() => _submitted = true);
    if (!_validate()) return;

    setState(() => _creating = true);
    try {
      final res = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (!mounted) return;
      // When email confirmation is enabled, no session comes back yet — the user
      // has to verify first. Otherwise they're signed in immediately.
      if (res.session == null) {
        _toast('Account created! Check your email to confirm, then sign in.');
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const AppLogo(size: 72),
              const SizedBox(height: 18),
              Text('Join the Ohana', style: AppTheme.headlineLg),
              const SizedBox(height: 10),
              Text(
                'Start your hydration journey today.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMd,
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Full Name',
                hintText: 'Lilo Pelekai',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Email Address',
                hintText: 'lilo@ohana.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
                onChanged: (_) => _revalidateIfSubmitted(),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                hintText: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscurable: true,
                textInputAction: TextInputAction.next,
                errorText: _passwordError,
                onChanged: _onPasswordChanged,
              ),
              PasswordStrengthBar(password: _passwordController.text),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Confirm Password',
                hintText: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _confirmController,
                obscurable: true,
                textInputAction: TextInputAction.done,
                errorText: _confirmError,
                onChanged: (_) => _revalidateIfSubmitted(),
                onSubmitted: (_) => _createAccount(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Create Account',
                  onPressed: _createAccount,
                  loading: _creating,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTheme.bodyMd),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('Sign In', style: AppTheme.link),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
