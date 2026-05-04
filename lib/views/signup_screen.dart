import 'package:aura/services/auth_service.dart';
import 'package:aura/theme/app_theme.dart';
import 'package:aura/viewmodel/signup_viewmodel.dart';
import 'package:aura/widgets/auth_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignUpViewModel(context.read<AuthService>()),
      child: Consumer<SignUpViewModel>(
        builder: (context, viewModel, _) {
          return AuthScreenShell(
            eyebrow: 'Create your space',
            title: 'Start a more welcoming health journey.',
            subtitle:
                'A cleaner onboarding flow, softer visuals, and an account experience that feels current.',
            icon: Icons.auto_awesome_rounded,
            formTitle: 'Create account',
            formSubtitle:
                'Set up your profile to access the assistant, save progress, and keep your sessions secure.',
            footer: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Log in'),
                ),
              ],
            ),
            child: Form(
              key: viewModel.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HighlightCard(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: viewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: viewModel.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) async {
                      if (viewModel.isLoading) {
                        return;
                      }

                      final didSignUp = await viewModel.signUp();
                      if (!context.mounted || !didSignUp) {
                        return;
                      }

                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Use at least 6 characters',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validator: viewModel.validatePassword,
                  ),
                  const SizedBox(height: 18),
                  const _PasswordHint(),
                  if (viewModel.authError != null) ...[
                    const SizedBox(height: 18),
                    _ErrorBanner(message: viewModel.authError!),
                  ],
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              final didSignUp = await viewModel.signUp();

                              if (!context.mounted || !didSignUp) {
                                return;
                              }

                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
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
                          : const Text('Create account'),
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

class _HighlightCard extends StatelessWidget {
  const _HighlightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF4FF), Color(0xFFF7FBFF)],
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniBadge(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your account unlocks a persistent assistant experience designed to feel calm, private, and easy to return to.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  const _PasswordHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.tips_and_updates_outlined, color: AppTheme.accent, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tip: combine letters, numbers, and something memorable to you.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
