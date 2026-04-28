import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../providers/explore_providers.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  static const topics = <_ExploreTopic>[
    _ExploreTopic(label: 'AI SaaS', tag: 'aisaas'),
    _ExploreTopic(label: 'AI Agents', tag: 'aiagents'),
    _ExploreTopic(label: 'Automation', tag: 'automation'),
    _ExploreTopic(label: 'Prompt Engineering', tag: 'prompts'),
    _ExploreTopic(label: 'AI Video', tag: 'aivideo'),
    _ExploreTopic(label: 'AI Sales', tag: 'aisales'),
    _ExploreTopic(label: 'AI Coding', tag: 'aicoding'),
    _ExploreTopic(label: 'AI Design', tag: 'aidesign'),
    _ExploreTopic(label: 'AI Education', tag: 'aieducation'),
    _ExploreTopic(label: 'No‑Code AI', tag: 'nocode'),
  ];

  static const links = <_ExploreLink>[
    _ExploreLink(
      title: 'OpenAI Blog',
      subtitle: 'Official releases and research updates',
      url: 'https://openai.com/blog',
    ),
    _ExploreLink(
      title: 'Google AI Blog',
      subtitle: 'Research and product announcements',
      url: 'https://ai.googleblog.com/',
    ),
    _ExploreLink(
      title: 'Anthropic News',
      subtitle: 'Model updates and safety posts',
      url: 'https://www.anthropic.com/news',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsState = ref.watch(trendingHashtagsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            onPressed: () => context.push('/network'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Network',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Network discovery'),
              subtitle: const Text(
                'Find collaboration matches, people you follow, and builders open to work together.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/network'),
            ),
          ),
          const SizedBox(height: AppSizes.xxxl),
          Text('Topics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: topics.map((topic) {
              return ActionChip(
                label: Text('#${topic.tag}'),
                onPressed: () => context.push('/hashtags/${topic.tag}'),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.xxxl),
          Text(
            'Trending hashtags',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          trendsState.when(
            data: (trends) {
              if (trends.isEmpty) {
                return const AppEmptyState(
                  title: 'No hashtags yet',
                  subtitle: 'Start a post with #hashtags to see them here.',
                  icon: Icons.tag,
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: trends.map((e) {
                  return ActionChip(
                    label: Text('#${e.tag} · ${e.count}'),
                    onPressed: () => context.push('/hashtags/${e.tag}'),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: AppLoader()),
            ),
            error: (error, stackTrace) => const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: Text('Unable to load trending hashtags.')),
            ),
          ),
          const SizedBox(height: AppSizes.xxxl),
          Text(
            'Media discovery',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.grid_view_rounded),
              title: Text('Coming soon'),
              subtitle: Text(
                'A grid for image/video discovery once the feed media viewer is fully polished.',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xxxl),
          Text('AI news links', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...links.map(
            (link) => _LinkCard(
              title: link.title,
              subtitle: link.subtitle,
              url: link.url,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreTopic {
  const _ExploreTopic({required this.label, required this.tag});

  final String label;
  final String tag;
}

class _ExploreLink {
  const _ExploreLink({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;
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
