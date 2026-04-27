import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_connectivity.dart';

/// A banner that shows when the device is offline.
///
/// This widget watches the [networkStatusProvider] and displays an orange
/// banner at the top of the screen when the device loses internet connection.
/// The banner is dismissible by swiping it away.
class NetworkStatusBanner extends ConsumerStatefulWidget {
  const NetworkStatusBanner({super.key});

  @override
  ConsumerState<NetworkStatusBanner> createState() =>
      _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends ConsumerState<NetworkStatusBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final networkStatus = ref.watch(networkStatusProvider);
        final isOffline = networkStatus.asData?.value == NetworkStatus.offline;

        if (_isDismissed || !isOffline) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Dismissible(
              key: const Key('offline-banner'),
              direction: DismissDirection.up,
              onDismissed: (_) {
                setState(() {
                  _isDismissed = true;
                });
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'re offline. Some features are unavailable.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDismissed = true;
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
