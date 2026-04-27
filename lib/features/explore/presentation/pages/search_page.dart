import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../feed/presentation/widgets/feed_post_card.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../profile/data/models/profile_model.dart';
import '../providers/explore_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialTab;

  const SearchPage({super.key, this.initialTab});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;

  final List<String> _tabs = ['Users', 'Posts', 'Hashtags', 'Products'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    int initialIndex = 0;
    if (widget.initialTab == 'products') {
      initialIndex = 3;
    }
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        FocusScope.of(context).requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: context.appColors.mutedText,
            ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
          onSubmitted: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserSearchResults(controller: _searchController),
          _PostSearchResults(controller: _searchController),
          _HashtagSearchResults(controller: _searchController),
          _ProductSearchResults(controller: _searchController),
        ],
      ),
    );
  }
}

class _UserSearchResults extends ConsumerWidget {
  final TextEditingController controller;

  const _UserSearchResults({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(userSearchResultsProvider);

    if (query.isEmpty) {
      return _EmptySearchState(
        title: 'Search for users',
        subtitle: 'Find builders by name, role, or skills',
      );
    }

    return searchResults.when(
      data: (users) {
        if (users.isEmpty) {
          return _EmptySearchState(
            title: 'No users found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.lg),
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserCard(user: user);
          },
        );
      },
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Error loading results',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final ProfileModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      child: InkWell(
        onTap: () {
          try {
            if (context.mounted) {
              context.push('/profiles/${user.uid}');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ErrorHandler.getUserFriendlyMessage(e),
                  ),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: [
              AppUserAvatar(
                avatarUrl: user.avatarUrl,
                radius: 32,
                onTap: () {
                  try {
                    if (context.mounted) {
                      context.push('/profiles/${user.uid}');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ErrorHandler.getUserFriendlyMessage(e),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: AppSizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.role.isNotEmpty)
                      Text(
                        user.role,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (user.skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.skills.take(3).map((skill) {
                          return Chip(
                            label: Text(skill),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
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

class _PostSearchResults extends ConsumerWidget {
  final TextEditingController controller;

  const _PostSearchResults({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(postSearchResultsProvider);

    if (query.isEmpty) {
      return _EmptySearchState(
        title: 'Search for posts',
        subtitle: 'Find posts by content or hashtags',
      );
    }

    return searchResults.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptySearchState(
            title: 'No posts found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.separated(
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final post = posts[index];
            return FeedPostCard(
              post: post,
              onCommentTap: () {
                try {
                  if (context.mounted) {
                    context.push('/posts/${post.id}', extra: post);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ErrorHandler.getUserFriendlyMessage(e),
                        ),
                      ),
                    );
                  }
                }
              },
              onTap: () {
                try {
                  if (context.mounted) {
                    context.push('/posts/${post.id}', extra: post);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ErrorHandler.getUserFriendlyMessage(e),
                        ),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Error loading results',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HashtagSearchResults extends ConsumerWidget {
  final TextEditingController controller;

  const _HashtagSearchResults({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(hashtagSearchResultsProvider);

    if (query.isEmpty) {
      return searchResults.when(
        data: (hashtags) {
          if (hashtags.isEmpty) {
            return _EmptySearchState(
              title: 'No trending hashtags',
              subtitle: 'Be the first to start a trend!',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.lg),
            itemCount: hashtags.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSizes.md),
            itemBuilder: (context, index) {
              final tag = hashtags[index];
              return _HashtagTile(tag: tag, label: 'Trending');
            },
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Error loading hashtags',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  ErrorHandler.getUserFriendlyMessage(error),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return searchResults.when(
      data: (hashtags) {
        if (hashtags.isEmpty) {
          return _EmptySearchState(
            title: 'No hashtags found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.lg),
          itemCount: hashtags.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final tag = hashtags[index];
            return _HashtagTile(tag: tag, label: 'Results');
          },
        );
      },
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Error loading results',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HashtagTile extends StatelessWidget {
  final String tag;
  final String label;

  const _HashtagTile({required this.tag, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      child: InkWell(
        onTap: () {
          try {
            if (context.mounted) {
              context.push('/hashtags/$tag');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ErrorHandler.getUserFriendlyMessage(e),
                  ),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$tag',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSearchResults extends ConsumerWidget {
  final TextEditingController controller;

  const _ProductSearchResults({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(productSearchResultsProvider);

    if (query.isEmpty) {
      return _EmptySearchState(
        title: 'Search for products',
        subtitle: 'Find products by name, category, or tags',
      );
    }

    return searchResults.when(
      data: (products) {
        if (products.isEmpty) {
          return _EmptySearchState(
            title: 'No products found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.lg),
          itemCount: products.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () {
                try {
                  if (context.mounted) {
                    context.push('/products/${product.id}');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ErrorHandler.getUserFriendlyMessage(e),
                        ),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Error loading results',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptySearchState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colors.mutedText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              subtitle,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
