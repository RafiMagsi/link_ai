import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class IAPRemoteDataSource {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<bool>? _purchaseCompleter;
  Completer<bool>? _restoreCompleter;
  String? _pendingProductId;

  Future<void> initialize() async {
    if (_purchaseSubscription != null) return;

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _completePendingPurchase(false);
        _completeRestore(false);
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
  Future<bool> purchaseSubscription(String productId) async {
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

      final purchased = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
      );

      if (!purchased) {
        return false;
      }

      _pendingProductId = productId;
      _purchaseCompleter = Completer<bool>();

      final result = await _purchaseCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _pendingProductId = null;
          _purchaseCompleter = null;
          return false;
        },
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      await initialize();
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _restoreCompleter = Completer<bool>();

      await _inAppPurchase.restorePurchases();

      final result = await _restoreCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _restoreCompleter = null;
          return false;
        },
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has an active subscription
  Future<bool> hasActiveSubscription(String uid) async {
    try {
      final subscriptionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('subscription')
          .doc('data');

      final doc = await subscriptionRef.get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) {
        return false;
      }

      final isActive = data['isGoldSubscriber'] == true;
      final expiresAt = data['expiresAt'] as Timestamp?;

      if (!isActive || expiresAt == null) {
        return false;
      }

      return expiresAt.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Create subscription in Firestore after successful purchase
  Future<void> _createSubscriptionInFirestore(String uid) async {
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    final expiresAtMs = DateTime.now().millisecondsSinceEpoch + thirtyDaysMs;
    final expiresAt = Timestamp.fromMillisecondsSinceEpoch(expiresAtMs);

    final subscriptionRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('subscription')
        .doc('data');

    await subscriptionRef.set({
      'uid': uid,
      'isGoldSubscriber': true,
      'subscribedAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'subscriptionStatus': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final user = _auth.currentUser;
    if (user == null) {
      _completePendingPurchase(false);
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
        case PurchaseStatus.error:
          if (_pendingProductId == purchase.productID) {
            _completePendingPurchase(false);
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
            }

            await _createSubscriptionInFirestore(user.uid);

            if (_pendingProductId == purchase.productID) {
              _completePendingPurchase(true);
            }
            _completeRestore(true);
          } catch (_) {
            if (_pendingProductId == purchase.productID) {
              _completePendingPurchase(false);
            }
            _completeRestore(false);
          }
          break;
      }
    }

    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      if (restoredProductSeen) return;
    }
  }

  void _completePendingPurchase(bool value) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(value);
    }
    _purchaseCompleter = null;
    _pendingProductId = null;
  }

  void _completeRestore(bool value) {
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete(value);
    }
    _restoreCompleter = null;
  }
}
