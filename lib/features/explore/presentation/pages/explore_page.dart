import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_ai/features/explore/presentation/widgets/shadow_style.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/explore_providers.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  static const topics = <_ExploreTopic>[
    _ExploreTopic(label: 'AI SaaS', tag: 'aisaas', icon: Icons.webhook_rounded),
    _ExploreTopic(label: 'AI Agents', tag: 'aiagents', icon: Icons.smart_toy_outlined),
    _ExploreTopic(label: 'Automation', tag: 'automation', icon: Icons.bolt_rounded),
    _ExploreTopic(label: 'Prompts', tag: 'prompts', icon: Icons.psychology_alt_outlined),
    _ExploreTopic(label: 'AI Video', tag: 'aivideo', icon: Icons.movie_creation_outlined),
    _ExploreTopic(label: 'AI Sales', tag: 'aisales', icon: Icons.trending_up_rounded),
    _ExploreTopic(label: 'AI Coding', tag: 'aicoding', icon: Icons.code_rounded),
    _ExploreTopic(label: 'AI Design', tag: 'aidesign', icon: Icons.auto_awesome_rounded),
  ];

  static const builders = <_FeaturedBuilder>[
    _FeaturedBuilder(
      name: 'Snow AI',
      role: 'Official AI curator',
      building: 'AI discovery feed',
      need: 'Great builders to feature',
      initials: 'AI',
      color: Color(0xFF60A5FA),
    ),
    _FeaturedBuilder(
      name: 'Rafi Khan',
      role: 'Flutter + AI builder',
      building: 'AI Links',
      need: 'Beta users and feedback',
      initials: 'RK',
      color: Color(0xFFA78BFA),
    ),
    _FeaturedBuilder(
      name: 'AI Builder Daily',
      role: 'Community prompts',
      building: 'Daily build challenges',
      need: 'Makers shipping AI tools',
      initials: 'BD',
      color: Color(0xFFF9A8D4),
    ),
  ];

  static const products = <_FeaturedProduct>[
    _FeaturedProduct(
      name: 'Resume Labs',
      tagline: 'AI resume builder for faster job applications.',
      tag: 'AI Career',
      icon: Icons.description_outlined,
      color: Color(0xFF60A5FA),
    ),
    _FeaturedProduct(
      name: 'VoicePost AI',
      tagline: 'Turn audio and podcasts into social content.',
      tag: 'Content AI',
      icon: Icons.mic_none_rounded,
      color: Color(0xFFA78BFA),
    ),
    _FeaturedProduct(
      name: 'PlotMotion AI',
      tagline: 'Create AI motion videos from structured prompts.',
      tag: 'AI Video',
      icon: Icons.video_camera_back_outlined,
      color: Color(0xFFF9A8D4),
    ),
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

    Future<void> refreshExplore() async {
      ref.invalidate(trendingHashtagsProvider);
      try {
        await ref.read(trendingHashtagsProvider.future);
      } catch (_) {
        // Keep the visible error state handled by the provider UI.
      }
    }

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
      body: RefreshIndicator.adaptive(
        onRefresh: refreshExplore,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.xxxl,
          ),
          children: [
          const _ExploreHero(),
          const SizedBox(height: AppSizes.xl),
          _SectionHeader(
            title: 'Trending now',
            subtitle: 'Hashtags people are using in AI Links.',
            actionText: 'Network',
            onActionTap: () => context.push('/network'),
          ),
          const SizedBox(height: AppSizes.md),
          trendsState.when(
            data: (trends) {
              if (trends.isEmpty) {
                return const AppEmptyState(
                  title: 'No hashtags yet',
                  subtitle: 'Start a post with #hashtags to see trends here.',
                  icon: Icons.tag,
                );
              }

              return Column(
                children: trends.take(6).toList().asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final trend = entry.value;
                  return _TrendingTile(
                    rank: rank,
                    tag: trend.tag,
                    count: trend.count,
                    onTap: () => context.push('/hashtags/${trend.tag}'),
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
          const SizedBox(height: AppSizes.xxl),
          const _SectionHeader(
            title: 'Featured builders',
            subtitle: 'People and official accounts building in AI.',
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: builders.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSizes.md),
              itemBuilder: (context, index) {
                return _BuilderCard(builder: builders[index]);
              },
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          _SectionHeader(
            title: 'Featured products',
            subtitle: 'AI tools and projects worth checking.',
            actionText: 'Products',
            onActionTap: () => context.push('/products'),
          ),
          const SizedBox(height: AppSizes.md),
          ...products.map((product) => _ProductCard(product: product)),
          const SizedBox(height: AppSizes.xxl),
          const _SectionHeader(
            title: 'Topics',
            subtitle: 'Jump into focused AI communities.',
          ),
          const SizedBox(height: AppSizes.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.75,
            ),
            itemBuilder: (context, index) {
              final topic = topics[index];
              return _TopicCard(
                topic: topic,
                onTap: () => context.push('/hashtags/${topic.tag}'),
              );
            },
          ),
          const SizedBox(height: AppSizes.xxl),
          const _SectionHeader(
            title: 'AI Radar',
            subtitle: 'Official AI updates and research sources.',
          ),
          const SizedBox(height: AppSizes.md),
          ...links.map(
            (link) => _LinkCard(
              title: link.title,
              subtitle: link.subtitle,
              url: link.url,
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _ExploreHero extends ConsumerWidget {
  const _ExploreHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGoldSubscriber = ref.watch(isGoldSubscriberProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colorScheme.surface,
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.10),
          width: 0.7,
        ),
        boxShadow: ShadowStyle.lightShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -72,
              right: -62,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF60A5FA).withValues(alpha: 0.06),
                      const Color(0xFF60A5FA).withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -84,
              left: -70,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF9A8D4).withValues(alpha: 0.06),
                      const Color(0xFFF9A8D4).withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFBFDBFE),
                          Color(0xDDD8B4FE),
                          Color(0xFFFBCFE8),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF312E81),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Discover AI builders, products, and ideas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Find people building in AI, explore trending topics, and discover tools from the community.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFBFDBFE),
                                Color(0xFFD8B4FE),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: Color(0xFF312E81),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ask Snow',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGoldSubscriber
                                    ? 'Open Snow AI chat for ideas and feedback.'
                                    : 'Gold members can chat with Snow AI.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        FilledButton.tonal(
                          onPressed: () => context.push(
                            isGoldSubscriber ? '/snow-chat' : '/subscription',
                          ),
                          child: Text(isGoldSubscriber ? 'Open' : 'Get Gold'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.md,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFA78BFA).withValues(alpha: 0.09),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              'Search builders, products, hashtags...',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (actionText != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionText!),
          ),
      ],
    );
  }
}

class _TrendingTile extends StatelessWidget {
  const _TrendingTile({
    required this.rank,
    required this.tag,
    required this.count,
    required this.onTap,
  });

  final int rank;
  final String tag;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
            ),
            boxShadow: ShadowStyle.lightShadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8F7FF),
                ),
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Color(0xFF6D28D9),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$tag',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count posts using this topic',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.trending_up_rounded, color: Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuilderCard extends StatelessWidget {
  const _BuilderCard({required this.builder});

  final _FeaturedBuilder builder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: builder.color.withValues(alpha: 0.10),
            width: 0.7,
          ),
          boxShadow: ShadowStyle.lightShadow(color: builder.color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: builder.color.withValues(alpha: 0.12),
                    child: Text(
                      builder.initials,
                      style: TextStyle(
                        color: builder.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 18),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                builder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                builder.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                'Building: ${builder.building}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Needs: ${builder.need}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _FeaturedProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.color.withValues(alpha: 0.10),
            width: 0.7,
          ),
          boxShadow: ShadowStyle.lightShadow(color: product.color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      product.color.withValues(alpha: 0.16),
                      product.color.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Icon(product.icon, color: product.color),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        _MiniBadge(label: product.tag),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final _ExploreTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
          ),
          boxShadow: ShadowStyle.lightShadow(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: [
              Icon(topic.icon, size: 20, color: const Color(0xFF7C3AED)),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${topic.tag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExploreTopic {
  const _ExploreTopic({
    required this.label,
    required this.tag,
    required this.icon,
  });

  final String label;
  final String tag;
  final IconData icon;
}

class _FeaturedBuilder {
  const _FeaturedBuilder({
    required this.name,
    required this.role,
    required this.building,
    required this.need,
    required this.initials,
    required this.color,
  });

  final String name;
  final String role;
  final String building;
  final String need;
  final String initials;
  final Color color;
}

class _FeaturedProduct {
  const _FeaturedProduct({
    required this.name,
    required this.tagline,
    required this.tag,
    required this.icon,
    required this.color,
  });

  final String name;
  final String tagline;
  final String tag;
  final IconData icon;
  final Color color;
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _copy(context),
        child: Ink(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
            ),
            boxShadow: ShadowStyle.lightShadow(),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
