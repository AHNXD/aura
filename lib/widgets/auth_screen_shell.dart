import 'package:aura/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.formTitle,
    required this.formSubtitle,
    required this.child,
    this.footer,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String formTitle;
  final String formSubtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _BrandPill(label: eyebrow),
                    const SizedBox(height: 20),
                    _HeroBanner(title: title, subtitle: subtitle, icon: icon),
                    const SizedBox(height: 24),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      Center(child: footer),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}
