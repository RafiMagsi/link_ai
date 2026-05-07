import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/iap_constants.dart';

class IAPProduct {
  final String id;
  final String title;
  final String description;
  final String price;

  const IAPProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });
}

enum IAPActionStatus { success, canceled, failed }

class IAPActionResult {
  const IAPActionResult({required this.status, required this.message});

  final IAPActionStatus status;
  final String message;

  bool get isSuccess => status == IAPActionStatus.success;

  static const IAPActionResult canceled = IAPActionResult(
    status: IAPActionStatus.canceled,
    message: 'Purchase was cancelled.',
  );

  static const IAPActionResult restoreEmpty = IAPActionResult(
    status: IAPActionStatus.failed,
    message: 'No active Gold subscription was found to restore.',
  );
}

class IAPRemoteDataSource {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<IAPActionResult>? _purchaseCompleter;
  Completer<IAPActionResult>? _restoreCompleter;
  String? _pendingProductId;

  Future<void> initialize() async {
    if (_purchaseSubscription != null) return;

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _completePendingPurchase(
          const IAPActionResult(
            status: IAPActionStatus.failed,
            message: 'Store purchase stream failed.',
          ),
        );
        _completeRestore(
          const IAPActionResult(
            status: IAPActionStatus.failed,
            message: 'Store restore stream failed.',
          ),
        );
      },
    );
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  /// Get available subscription products from the app store
  Future<List<IAPProduct>> getSubscriptionProducts() async {
    try {
      await initialize();
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw Exception(
          'In-app purchases are not available on this device. '
          'Test on a real device using TestFlight (iOS) or an internal '
          'testing track (Android).',
        );
      }

      final response = await _inAppPurchase.queryProductDetails({
        IAPConstants.goldSubscriptionProductId,
      });

      if (response.error != null) {
        throw Exception(
          'Store error: ${response.error!.message} (${response.error!.code})',
        );
      }

      if (response.productDetails.isEmpty) {
        throw Exception(
          'Product not found in the store. Make sure '
          '\'${IAPConstants.goldSubscriptionProductId}\' '
          'exists in App Store Connect / Play Console and you are running '
          'from TestFlight / an internal testing track.',
        );
      }

      return response.productDetails
          .map(
            (product) => IAPProduct(
              id: product.id,
              title: product.title,
              description: product.description,
              price: product.price,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load product details: $e');
    }
  }

  /// Purchase a subscription
  Future<IAPActionResult> purchaseSubscription(String productId) async {
    try {
      await initialize();
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw Exception('In-app purchases are not available');
      }

      final response = await _inAppPurchase.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        throw Exception('Product not found');
      }

      final productDetails = response.productDetails.first;
      final appAccountToken = _appAccountToken(user.uid);

      final purchased = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: productDetails,
          applicationUserName: appAccountToken,
        ),
      );

      if (!purchased) {
        return IAPActionResult.canceled;
      }

      _pendingProductId = productId;
      _purchaseCompleter = Completer<IAPActionResult>();

      final result = await _purchaseCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _pendingProductId = null;
          _purchaseCompleter = null;
          return const IAPActionResult(
            status: IAPActionStatus.failed,
            message: 'Purchase verification timed out. Try restore later.',
          );
        },
      );
      return result;
    } catch (e) {
      return IAPActionResult(
        status: IAPActionStatus.failed,
        message: 'Purchase failed: $e',
      );
    }
  }

  /// Restore previous purchases
  Future<IAPActionResult> restorePurchases() async {
    try {
      await initialize();
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _restoreCompleter = Completer<IAPActionResult>();

      await _inAppPurchase.restorePurchases(
        applicationUserName: _appAccountToken(user.uid),
      );

      final result = await _restoreCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _restoreCompleter = null;
          return const IAPActionResult(
            status: IAPActionStatus.failed,
            message: 'Restore timed out. Try again.',
          );
        },
      );
      return result;
    } catch (e) {
      return IAPActionResult(
        status: IAPActionStatus.failed,
        message: 'Restore failed: $e',
      );
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final user = _auth.currentUser;
    if (user == null) {
      _completePendingPurchase(
        const IAPActionResult(
          status: IAPActionStatus.failed,
          message: 'User not authenticated.',
        ),
      );
      return;
    }

    var restoredProductSeen = false;

    for (final purchase in purchases) {
      final isGoldSubscription =
          purchase.productID == IAPConstants.goldSubscriptionProductId;
      if (!isGoldSubscription) {
        continue;
      }

      if (purchase.status == PurchaseStatus.restored) {
        restoredProductSeen = true;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          if (_pendingProductId == purchase.productID) {
            _completePendingPurchase(IAPActionResult.canceled);
          }
          break;
        case PurchaseStatus.error:
          if (_pendingProductId == purchase.productID) {
            _completePendingPurchase(
              IAPActionResult(
                status: IAPActionStatus.failed,
                message: purchase.error?.message ?? 'Store purchase failed.',
              ),
            );
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final syncResult = await _syncGoldSubscription(
              purchase: purchase,
              uid: user.uid,
            );

            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
            }

            if (_pendingProductId == purchase.productID) {
              _completePendingPurchase(syncResult);
            }
            _completeRestore(syncResult);
          } catch (error) {
            if (_pendingProductId == purchase.productID) {
              _completePendingPurchase(
                IAPActionResult(
                  status: IAPActionStatus.failed,
                  message: 'Verification failed: $error',
                ),
              );
            }
            _completeRestore(
              IAPActionResult(
                status: IAPActionStatus.failed,
                message: 'Restore failed: $error',
              ),
            );
          }
          break;
      }
    }

    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      if (!restoredProductSeen) {
        _completeRestore(IAPActionResult.restoreEmpty);
      }
    }
  }

  Future<IAPActionResult> _syncGoldSubscription({
    required PurchaseDetails purchase,
    required String uid,
  }) async {
    final purchaseId = purchase.purchaseID;
    final productId = purchase.productID;
    final verificationData = purchase.verificationData.serverVerificationData;

    if (purchase.verificationData.source != 'app_store') {
      throw Exception(
        'Gold verification is currently configured for App Store only.',
      );
    }

    if ((purchaseId == null || purchaseId.isEmpty) &&
        verificationData.isEmpty) {
      throw Exception('Missing purchase verification data.');
    }

    final callable = _functions.httpsCallable('syncGoldSubscription');
    final response = await callable.call<Map<String, dynamic>>({
      'uid': uid,
      'purchaseSource': purchase.verificationData.source,
      'productId': productId,
      'transactionId': purchaseId,
      'serverVerificationData': verificationData,
    });

    final data = response.data;
    final isActive = data['isActive'] == true;
    final status = data['subscriptionStatus'] as String? ?? 'inactive';
    final expiresAt = data['expiresAt'] as String?;

    if (!isActive) {
      return IAPActionResult(
        status: IAPActionStatus.failed,
        message: expiresAt == null
            ? 'Gold is not active for this Apple account.'
            : 'Gold is not active. Expired on ${expiresAt.split('T').first}.',
      );
    }

    return IAPActionResult(
      status: IAPActionStatus.success,
      message: status == 'active'
          ? 'Gold is active.'
          : 'Gold synced successfully.',
    );
  }

  String _appAccountToken(String uid) {
    return _uuid.v5(Namespace.url.value, 'ai-links:$uid');
  }

  void _completePendingPurchase(IAPActionResult value) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(value);
    }
    _purchaseCompleter = null;
    _pendingProductId = null;
  }

  void _completeRestore(IAPActionResult value) {
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete(value);
    }
    _restoreCompleter = null;
  }
}
