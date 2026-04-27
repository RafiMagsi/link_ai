import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/skeleton_post_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../../feed/presentation/widgets/feed_post_card.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../products/presentation/providers/product_providers.dart';

class SavedItemsPage extends ConsumerStatefulWidget {
  const SavedItemsPage({super.key});

  @override
  ConsumerState<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends ConsumerState<SavedItemsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: AppLoader())
          : TabBarView(
              controller: _tabController,
              children: [
                _SavedPostsTab(uid: uid),
                _SavedProductsTab(uid: uid),
              ],
            ),
    );
  }
}

class _SavedPostsTab extends ConsumerWidget {
  const _SavedPostsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIdsState = ref.watch(savedPostIdsByUserProvider(uid));
    final cached = savedIdsState.error == null ? savedIdsState.value : null;

    Widget buildList(List<String> postIds) {
      if (postIds.isEmpty) {
        return const AppEmptyState(
          title: 'No saved posts',
          subtitle: 'Posts you save will show up here.',
          icon: Icons.bookmark_border,
        );
      }

      return ListView.separated(
        itemCount: postIds.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final postState = ref.watch(postByIdProvider(postIds[index]));

          return postState.when(
            data: (post) {
              if (post == null) return const SizedBox.shrink();
              return FeedPostCard(
                post: post,
                onTap: () => context.push('/posts/${post.id}', extra: post),
                onCommentTap: () =>
                    context.push('/posts/${post.id}', extra: post),
              );
            },
            loading: () => const SkeletonPostCard(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          );
        },
      );
    }

    if (cached != null) return buildList(cached);

    return savedIdsState.when(
      data: buildList,
      loading: () => ListView.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const SkeletonPostCard(),
      ),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load saved posts.')),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _SavedProductsTab extends ConsumerWidget {
  const _SavedProductsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIdsState = ref.watch(savedProductIdsByUserProvider(uid));
    final cached = savedIdsState.error == null ? savedIdsState.value : null;

    Widget buildList(List<String> productIds) {
      if (productIds.isEmpty) {
        return const AppEmptyState(
          title: 'No saved products',
          subtitle: 'Products you save will show up here.',
          icon: Icons.inventory_2_outlined,
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: productIds.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final productState = ref.watch(
            productDetailProvider(productIds[index]),
          );

          return productState.when(
            data: (product) {
              if (product == null) return const SizedBox.shrink();
              return ProductCard(
                product: product,
                onTap: () => context.push('/products/${product.id}'),
              );
            },
            loading: () => const _SavedProductSkeleton(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          );
        },
      );
    }

    if (cached != null) return buildList(cached);

    return savedIdsState.when(
      data: buildList,
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const _SavedProductSkeleton(),
      ),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load saved products.')),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _SavedProductSkeleton extends StatelessWidget {
  const _SavedProductSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
