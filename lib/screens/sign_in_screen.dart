import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_background.dart';
import '../widgets/primary_button.dart';
import 'dashboard_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signingIn = false;

  // Per-field inline errors. Null = no error shown.
  String? _emailError;
  String? _passwordError;
  // Once the user has tried to submit once, re-validate live as they type so
  // errors clear the moment they're fixed.
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs the field validators and updates the inline errors. Returns true when
  /// everything passes.
  bool _validate() {
    setState(() {
      _emailError = Validators.email(_emailController.text);
      _passwordError = Validators.requiredPassword(_passwordController.text);
    });
    return _emailError == null && _passwordError == null;
  }

  void _revalidateIfSubmitted() {
    if (_submitted) _validate();
  }

  Future<void> _signIn() async {
    if (_signingIn) return;
    setState(() => _submitted = true);
    if (!_validate()) return;

    setState(() => _signingIn = true);
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on AuthException catch (e) {
      // Server-side errors (e.g. wrong credentials) aren't tied to one field,
      // so they surface as a snackbar.
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const AppLogo(size: 96),
              const SizedBox(height: 20),
              Text('HydroTracker', style: AppTheme.headlineLg),
              const SizedBox(height: 16),
              Text(
                'Welcome back, Experiment 626',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMd,
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Email',
                hintText: 'lilo@ohana.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
                onChanged: (_) => _revalidateIfSubmitted(),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Password',
                hintText: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscurable: true,
                textInputAction: TextInputAction.done,
                errorText: _passwordError,
                onChanged: (_) => _revalidateIfSubmitted(),
                onSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Forgot password?', style: AppTheme.link),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Sign In',
                  onPressed: _signIn,
                  loading: _signingIn,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New to the island? ', style: AppTheme.bodyMd),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: Text('Join the Ohana', style: AppTheme.link),
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
