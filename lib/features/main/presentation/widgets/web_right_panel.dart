import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../explore/presentation/providers/explore_providers.dart';

class WebRightPanel extends ConsumerWidget {
  const WebRightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.8,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBox(context: context),
                const SizedBox(height: 28),
                _SearchFilters(context: context),
                const SizedBox(height: 36),
                _TrendingSection(ref: ref, context: context),
                const SizedBox(height: 36),
                _PeopleToFollowSection(ref: ref, context: context),
                const SizedBox(height: 40),
                _FooterLinks(context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({required this.context});
  final BuildContext context;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.6,
        ),
      ),
      child: SearchBar(
        controller: _controller,
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.search, size: 20),
        ),
        hintText: 'Search people, projects...',
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.push('/search', extra: query);
            _controller.clear();
          }
        },
      ),
    );
  }
}

class _SearchFilters extends StatelessWidget {
  const _SearchFilters({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _FilterTile(label: 'From anyone', context: context),
        _FilterTile(label: 'People you follow', context: context),
        const SizedBox(height: 12),
        Text(
          'Location',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _FilterTile(label: 'Anywhere', context: context),
        _FilterTile(label: 'Near you', context: context),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {},
          child: Text(
            'Advanced search',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({required this.label, required this.context});
  final String label;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
          ),
        ),
      ),
    );
  }
}

class _TrendingSection extends ConsumerWidget {
  const _TrendingSection({
    required this.ref,
    required this.context,
  });

  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendingHashtagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 16),
        trendsAsync.when(
          data: (trends) {
            if (trends.isEmpty) {
              return Text(
                'No trends yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              );
            }

            return Column(
              children: trends.take(5).map((trend) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.push('/hashtags/${trend.tag}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 0.6,
                        ),
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${trend.tag}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${trend.count} posts',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (error, _) => Text(
            'Could not load trends',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ],
    );
  }
}

class _PeopleToFollowSection extends ConsumerWidget {
  const _PeopleToFollowSection({
    required this.ref,
    required this.context,
  });

  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for people to follow
    final people = [
      {'name': 'Tech Daily Updates', 'handle': '@techdaily', 'followers': '2.1M'},
      {'name': 'Developer Tips', 'handle': '@devtips', 'followers': '856K'},
      {'name': 'AI Innovations', 'handle': '@aiinnovations', 'followers': '1.3M'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who to follow',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 16),
        Column(
          children: people.map((person) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.6,
                  ),
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person['name']!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            person['handle']!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {},
          child: Text(
            'Show more',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _FooterLink(label: 'Terms of Service', context: context),
            Text('·', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            )),
            _FooterLink(label: 'Privacy Policy', context: context),
            Text('·', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            )),
            _FooterLink(label: 'Cookie Policy', context: context),
            Text('·', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            )),
            _FooterLink(label: 'Accessibility', context: context),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            _FooterLink(label: 'Ads info', context: context),
            Text('·', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            )),
            _FooterLink(label: 'More', context: context),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '© 2026 LinkAI',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.context});
  final String label;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}
