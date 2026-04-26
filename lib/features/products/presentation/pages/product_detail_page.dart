import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/product_providers.dart';
import 'edit_product_page.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productDetailProvider(productId));
    final currentUser = ref.watch(currentUserProvider);
    final saveState = ref.watch(productSaveStateProvider(productId));

    return productState.when(
      data: (product) {
        if (product == null) {
          return const Scaffold(
            body: Center(child: Text('Product not found.')),
          );
        }

        final isOwner = currentUser?.uid == product.ownerUid;
        final isSaved = saveState.asData?.value == true;

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              if (isOwner)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProductPage(product: product),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (product.screenshots.isNotEmpty)
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    itemCount: product.screenshots.length,
                    itemBuilder: (context, index) {
                      final screenshot = product.screenshots[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            screenshot.url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, size: 56),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.tagline,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(product.category)),
                  if (product.pricing.isNotEmpty)
                    Chip(label: Text(product.pricing)),
                  if (product.version.isNotEmpty)
                    Chip(label: Text('v${product.version}')),
                  Chip(label: Text('${product.savesCount} saves')),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(productControllerProvider.notifier)
                            .toggleSaveProduct(product.id);
                      },
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(isSaved ? 'Saved' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: product.websiteUrl.isEmpty
                          ? null
                          : () {
                              // Later: open url_launcher.
                            },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Visit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                product.description.isEmpty
                    ? 'No description added.'
                    : product.description,
                style: const TextStyle(height: 1.45),
              ),
              const SizedBox(height: 24),
              const Text(
                'Built with / Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Platforms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.platforms
                    .map((platform) => Chip(label: Text(platform)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: product.ownerAvatarUrl != null
                      ? NetworkImage(product.ownerAvatarUrl!)
                      : null,
                  child: product.ownerAvatarUrl == null
                      ? Text(
                          product.ownerName.isNotEmpty
                              ? product.ownerName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(product.ownerName),
                subtitle: Text(product.ownerRole),
              ),
              if (isOwner) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(productControllerProvider.notifier)
                        .unlistProduct(product.id);
                  },
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Unlist Product'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(productControllerProvider.notifier)
                        .archiveProduct(product.id);
                  },
                  icon: const Icon(Icons.archive),
                  label: const Text('Archive Product'),
                ),
              ],
            ],
          ),
        );
      },
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        return const Scaffold(
          body: Center(child: Text('Unable to load product.')),
        );
      },
    );
  }
}
