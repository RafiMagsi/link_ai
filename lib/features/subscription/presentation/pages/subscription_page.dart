import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_loader.dart';
import '../../data/datasources/iap_remote_datasource.dart';
import '../../data/models/iap_constants.dart';
import '../../data/models/subscription_model.dart';
import '../providers/iap_providers.dart';
import '../providers/subscription_providers.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  Future<void> _purchaseSubscription(String productId) async {
    setState(() => _isPurchasing = true);
    final result = await ref
        .read(iapControllerProvider)
        .purchaseSubscription(productId);
    if (!mounted) return;
    setState(() => _isPurchasing = false);
    _showMessage(result.message);
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    final result = await ref.read(iapControllerProvider).restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);
    _showMessage(result.message);
  }

  Future<void> _openManageSubscriptions() async {
    final isApplePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final uri = Uri.parse(
      isApplePlatform
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(userSubscriptionProvider);
    final productsState = ref.watch(subscriptionProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gold')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionProductsProvider);
          ref.invalidate(userSubscriptionProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            subscriptionState.when(
              data: (subscription) => _SubscriptionStatusCard(
                subscription: subscription,
                onManageTap: _openManageSubscriptions,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: AppLoader()),
              ),
              error: (error, _) => _InlineErrorCard(
                title: 'Subscription status unavailable',
                message: '$error',
              ),
            ),
            const SizedBox(height: 16),
            _FeatureCard(
              features: const [
                'Ask @snow for AI feedback on posts',
                'Gold badge on your profile and activity',
                'Priority access to future AI features',
              ],
            ),
            const SizedBox(height: 16),
            productsState.when(
              data: (products) {
                if (products.isEmpty) {
                  return const _InlineErrorCard(
                    title: 'Gold product unavailable',
                    message:
                        'Create the product in App Store Connect and test '
                        'from TestFlight.',
                  );
                }
                final product = products.firstWhere(
                  (item) => item.id == IAPConstants.goldSubscriptionProductId,
                  orElse: () => products.first,
                );
                return _PurchaseCard(
                  product: product,
                  isPurchasing: _isPurchasing,
                  isRestoring: _isRestoring,
                  onSubscribe: () => _purchaseSubscription(product.id),
                  onRestore: _restorePurchases,
                  onManage: _openManageSubscriptions,
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: AppLoader()),
              ),
              error: (error, _) => _InlineErrorCard(
                title: 'Unable to load Gold pricing',
                message: '$error',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  const _SubscriptionStatusCard({
    required this.subscription,
    required this.onManageTap,
  });

  final SubscriptionModel? subscription;
  final Future<void> Function() onManageTap;

  @override
  Widget build(BuildContext context) {
    final active = subscription?.isActive ?? false;
    final title = active ? 'Gold active' : 'Gold inactive';
    final subtitle = active
        ? 'Your Gold access is verified by the store.'
        : 'Gold unlocks @snow and premium AI tools.';
    final expiresText = subscription?.expiresAt == null
        ? null
        : subscription!.expiresAt!.toIso8601String().split('T').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? const Color(0xFFFFD54F)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: active
                    ? const Color(0xFFFFC107)
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          if (expiresText != null) ...[
            const SizedBox(height: 10),
            Text(
              'Expires $expiresText',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onManageTap,
            child: const Text('Manage subscriptions'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Gold gives you',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.product,
    required this.isPurchasing,
    required this.isRestoring,
    required this.onSubscribe,
    required this.onRestore,
    required this.onManage,
  });

  final IAPProduct product;
  final bool isPurchasing;
  final bool isRestoring;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 16),
          Text(
            product.price,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isPurchasing ? null : onSubscribe,
              child: isPurchasing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Subscribe to Gold'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isRestoring ? null : onRestore,
                  child: isRestoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Restore'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onManage,
                  child: const Text('Manage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
