import 'package:flutter/material.dart';

import '../errors/error_handler.dart';

/// A reusable error widget with a retry button.
///
/// Usage:
/// ```dart
/// asyncValue.when(
///   data: (data) => YourWidget(data: data),
///   loading: () => const Center(child: CircularProgressIndicator()),
///   error: (error, stackTrace) => RetryErrorWidget(
///     error: error,
///     onRetry: () => ref.invalidate(yourProvider),
///   ),
/// )
/// ```
class RetryErrorWidget extends StatelessWidget {
  const RetryErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.message,
  });

  final dynamic error;
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? ErrorHandler.getUserFriendlyMessage(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A variant for small inline errors with minimal space.
class InlineRetryErrorWidget extends StatelessWidget {
  const InlineRetryErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.message,
  });

  final dynamic error;
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? ErrorHandler.getUserFriendlyMessage(error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
