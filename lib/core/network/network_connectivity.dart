import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enum representing different network statuses.
enum NetworkStatus {
  online,
  offline,
  reconnecting,
}

/// Provider that monitors the device's network connectivity status.
///
/// Usage:
/// ```dart
/// final networkStatus = ref.watch(networkStatusProvider);
/// if (networkStatus == NetworkStatus.offline) {
///   // Handle offline state
/// }
/// ```
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = Connectivity();

  try {
    // Get initial status
    final results = await connectivity.checkConnectivity();
    yield _mapConnectivityListToStatus(results);

    // Listen for changes
    await for (final results in connectivity.onConnectivityChanged) {
      try {
        yield _mapConnectivityListToStatus(results);
      } catch (e) {
        debugPrint('Error processing connectivity change: $e');
        yield NetworkStatus.offline;
      }
    }
  } on MissingPluginException catch (e) {
    debugPrint('Connectivity plugin is not registered. Restart the app: $e');
    yield NetworkStatus.offline;
  } catch (e) {
    debugPrint('Error checking connectivity: $e');
    yield NetworkStatus.offline;
  }
});

/// Provider that indicates if the device is currently online.
///
/// Usage:
/// ```dart
/// final isOnline = ref.watch(isOnlineProvider);
/// ```
final isOnlineProvider = Provider<bool>((ref) {
  try {
    final networkStatus = ref.watch(networkStatusProvider);
    return networkStatus.asData?.value == NetworkStatus.online;
  } catch (e) {
    debugPrint('Error in isOnlineProvider: $e');
    return false;
  }
});

/// Maps a list of [ConnectivityResult] to [NetworkStatus].
NetworkStatus _mapConnectivityListToStatus(List<ConnectivityResult> results) {
  try {
    if (results.isEmpty) {
      return NetworkStatus.offline;
    }

    // If any result is online, consider the device online
    for (final result in results) {
      try {
        if (_mapConnectivityToStatus(result) == NetworkStatus.online) {
          return NetworkStatus.online;
        }
      } catch (e) {
        debugPrint('Error mapping connectivity result: $e');
        continue;
      }
    }

    return NetworkStatus.offline;
  } catch (e) {
    debugPrint('Error in mapConnectivityListToStatus: $e');
    return NetworkStatus.offline;
  }
}

/// Maps a single [ConnectivityResult] to [NetworkStatus].
NetworkStatus _mapConnectivityToStatus(ConnectivityResult result) {
  try {
    return switch (result) {
      ConnectivityResult.none => NetworkStatus.offline,
      ConnectivityResult.mobile => NetworkStatus.online,
      ConnectivityResult.wifi => NetworkStatus.online,
      ConnectivityResult.ethernet => NetworkStatus.online,
      ConnectivityResult.vpn => NetworkStatus.online,
      ConnectivityResult.bluetooth => NetworkStatus.online,
      ConnectivityResult.satellite => NetworkStatus.online,
      ConnectivityResult.other => NetworkStatus.online,
    };
  } catch (e) {
    debugPrint('Error mapping connectivity status: $e');
    return NetworkStatus.offline;
  }
}
