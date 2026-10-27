import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAuth(BuildContext context, AuthMode mode) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AuthScreen(mode: mode)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookShelf'),
        actions: [
          TextButton(
            onPressed: () => _openAuth(context, AuthMode.login),
            child: const Text('Login'),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
            child: FilledButton.tonal(
              onPressed: () => _openAuth(context, AuthMode.register),
              child: const Text('Register'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpace.xl),
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 72,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    'BookShelf',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Your private place to organize every book you own and want to read.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  const Wrap(
                    spacing: AppSpace.md,
                    runSpacing: AppSpace.md,
                    alignment: WrapAlignment.center,
                    children: [
                      _FeatureCard(
                        icon: Icons.library_books_rounded,
                        title: 'Track your books',
                        detail:
                            'Keep your personal library in one secure place.',
                      ),
                      _FeatureCard(
                        icon: Icons.filter_alt_rounded,
                        title: 'Sort by status',
                        detail: 'Find what you are reading or planning next.',
                      ),
                      _FeatureCard(
                        icon: Icons.star_rounded,
                        title: 'Rate your favorites',
                        detail: 'Save ratings, notes, and favorite titles.',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  FilledButton.icon(
                    onPressed: () => _openAuth(context, AuthMode.register),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpace.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
