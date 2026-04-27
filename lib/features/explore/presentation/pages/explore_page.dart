import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/utils/hashtag_utils.dart';
import '../../../feed/presentation/providers/post_providers.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  static const categories = [
    'AI SaaS',
    'AI Agents',
    'Automation',
    'Prompt Engineering',
    'AI Video',
    'AI Sales',
    'AI Coding',
    'AI Design',
    'AI Education',
    'No-Code AI',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestState = ref.watch(latestPostsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Discover AI builders by category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((category) {
              return ActionChip(label: Text(category), onPressed: () {});
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Trending hashtags',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          latestState.when(
            data: (posts) {
              final counts = <String, int>{};
              for (final post in posts) {
                final tags = post.hashtags.isNotEmpty
                    ? post.hashtags
                    : HashtagUtils.extractNormalized(post.text);
                for (final t in tags) {
                  counts[t] = (counts[t] ?? 0) + 1;
                }
              }

              final top = counts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              if (top.isEmpty) {
                return const AppEmptyState(
                  title: 'No hashtags yet',
                  subtitle: 'Start a post with #hashtags to see them here.',
                  icon: Icons.tag,
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: top.take(20).map((e) {
                  return ActionChip(
                    label: Text('#${e.key} · ${e.value}'),
                    onPressed: () => context.push('/hashtags/${e.key}'),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: Text('Unable to load trending hashtags.')),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'AI news (links)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _LinkCard(
            title: 'OpenAI Blog',
            subtitle: 'Official releases and research updates',
            url: 'https://openai.com/blog',
          ),
          _LinkCard(
            title: 'Google AI Blog',
            subtitle: 'Research and product announcements',
            url: 'https://ai.googleblog.com/',
          ),
          _LinkCard(
            title: 'Anthropic News',
            subtitle: 'Model updates and safety posts',
            url: 'https://www.anthropic.com/news',
          ),
          const SizedBox(height: 28),
          Text(
            'People looking for help',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            title: 'Need beta users',
            subtitle: 'AI founders testing MVPs',
            icon: Icons.rocket_launch_outlined,
          ),
          _ExploreCard(
            title: 'Need collaborators',
            subtitle: 'Builders looking for designers, devs, and marketers',
            icon: Icons.groups_outlined,
          ),
          _ExploreCard(
            title: 'Need feedback',
            subtitle: 'Projects waiting for honest product review',
            icon: Icons.rate_review_outlined,
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.link),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.copy),
        onTap: () => _copy(context),
      ),
    );
  }
}
