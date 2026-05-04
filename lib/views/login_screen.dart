import 'package:aura/services/auth_service.dart';
import 'package:aura/theme/app_theme.dart';
import 'package:aura/viewmodel/login_viewmodel.dart';
import 'package:aura/views/signup_screen.dart';
import 'package:aura/widgets/auth_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel(context.read<AuthService>()),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return AuthScreenShell(
            eyebrow: 'Aura Care',
            title: 'Feel supported from the first screen.',
            subtitle:
                'Secure access, calmer visuals, and a clearer path back into your health assistant.',
            icon: Icons.favorite_rounded,
            formTitle: 'Welcome back',
            formSubtitle:
                'Sign in to continue your conversations and manage your account with confidence.',
            footer: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New here?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                  child: const Text('Create account'),
                ),
              ],
            ),
            child: Form(
              key: viewModel.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _InfoStrip(
                    icon: Icons.shield_outlined,
                    text: 'Private sign-in with Firebase Authentication.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: viewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: viewModel.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!viewModel.isLoading) {
                        viewModel.login();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: viewModel.validatePassword,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              final message = await viewModel
                                  .onForgotPasswordTapped();

                              if (!context.mounted || message == null) {
                                return;
                              }

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (viewModel.authError != null) ...[
                    const SizedBox(height: 6),
                    _ErrorBanner(message: viewModel.authError!),
                  ],
                  const SizedBox(height: 22),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              await viewModel.login();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Log in'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD3DB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, color: AppTheme.error),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
