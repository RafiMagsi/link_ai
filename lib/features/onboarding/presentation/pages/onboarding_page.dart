import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  Future<void> _dismissOnboarding(WidgetRef ref) async {
    final settings = ref.read(userSettingsProvider).value;
    if (settings == null) return;

    final updatedSettings = settings.copyWith(
      onboardingShown: true,
      lastOnboardingDismissAt: DateTime.now(),
    );

    await ref
        .read(settingsControllerProvider.notifier)
        .updateSettings(updatedSettings);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Welcome to ${AppStrings.appName}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show what you\'re building in AI and connect with builders',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              // Feature Cards
              _FeatureCard(
                icon: Icons.build_circle_outlined,
                title: 'Build & Share',
                description:
                    'Showcase what you\'re building in AI and share your progress',
              ),
              const SizedBox(height: 20),
              _FeatureCard(
                icon: Icons.people_outline,
                title: 'Discover Builders',
                description:
                    'Find like-minded AI enthusiasts and connect with your community',
              ),
              const SizedBox(height: 20),
              _FeatureCard(
                icon: Icons.handshake_outlined,
                title: 'Follow & Collaborate',
                description:
                    'Follow AI builders and start conversations around real projects',
              ),
              const SizedBox(height: 20),
              _FeatureCard(
                icon: Icons.trending_up_outlined,
                title: 'Grow Your Network',
                description:
                    'Build meaningful relationships with AI builders and creators',
              ),
              const SizedBox(height: 48),
              // Action Buttons
              FilledButton(
                onPressed: () {
                  context.go('/profile/edit');
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Complete Your Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await _dismissOnboarding(ref);
                  if (context.mounted) {
                    context.go('/feed');
                  }
                },
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 24),
            ],
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
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
