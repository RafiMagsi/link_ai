import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/iap_remote_datasource.dart';

final iapRemoteDataSourceProvider = Provider<IAPRemoteDataSource>((ref) {
  return IAPRemoteDataSource();
});

final subscriptionProductsProvider = FutureProvider<List<IAPProduct>>((ref) {
  return ref.watch(iapRemoteDataSourceProvider).getSubscriptionProducts();
});

class IAPController {
  IAPController(this._dataSource);

  final IAPRemoteDataSource _dataSource;

  Future<bool> purchaseSubscription(String productId) async {
    return await _dataSource.purchaseSubscription(productId);
  }

  Future<bool> restorePurchases() async {
    return await _dataSource.restorePurchases();
  }
}

final iapControllerProvider = Provider<IAPController>((ref) {
  return IAPController(ref.watch(iapRemoteDataSourceProvider));
});
