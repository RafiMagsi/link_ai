import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_loader.dart';
import '../../data/models/subscription_model.dart';
import '../providers/subscription_providers.dart';
import '../providers/iap_providers.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _isLoading = false;

  Future<void> _purchaseSubscription() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref
          .read(iapControllerProvider)
          .purchaseSubscription('gold_subscription_monthly');

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase was cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(userSubscriptionProvider);
    final isGoldSubscriber = ref.watch(isGoldSubscriberProvider);
    final productsState = ref.watch(subscriptionProductsProvider); // ignore: unused_local_variable

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Subscription'),
        centerTitle: true,
      ),
      body: subscriptionState.when(
        data: (subscription) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGoldSubscriber)
                  _buildActiveSubscriptionSection(context, subscription)
                else
                  _buildSubscriptionPromotionSection(context),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionSection(BuildContext context, SubscriptionModel? subscriptionData) {
    if (subscriptionData == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'You are a Gold Subscriber',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Expires: ${subscriptionData.expiresAt?.toString().split(' ')[0] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Enjoy exclusive features including access to @Snow AI and more!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPromotionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Gold Subscription',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                '\$5 per month',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Features:'),
              const SizedBox(height: 8),
              _buildFeatureItem('Access @Snow AI chatbot'),
              _buildFeatureItem('Gold star badge on your profile'),
              _buildFeatureItem('Gold star on your posts and comments'),
              _buildFeatureItem('Premium support'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _purchaseSubscription,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Subscribe Now'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}
