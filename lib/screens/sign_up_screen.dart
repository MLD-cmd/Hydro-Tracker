import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_background.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _createAccount() {
    // No backend yet — go straight to the dashboard for the flow.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
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
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                hintText: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscurable: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Confirm Password',
                hintText: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _confirmController,
                obscurable: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _createAccount(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Create Account',
                  onPressed: _createAccount,
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
