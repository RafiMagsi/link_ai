import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((
  ref,
) {
  return ProductRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final publicProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRemoteDataSourceProvider).watchPublicProducts();
});

final myProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(productRemoteDataSourceProvider).watchMyProducts(user.uid);
});

final productDetailProvider = StreamProvider.family<ProductModel?, String>((
  ref,
  productId,
) {
  return ref.watch(productRemoteDataSourceProvider).watchProduct(productId);
});

final productSaveStateProvider = FutureProvider.family<bool, String>((
  ref,
  productId,
) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) return false;

  return ref
      .watch(productRemoteDataSourceProvider)
      .hasSavedProduct(productId: productId, uid: user.uid);
});

final productControllerProvider =
    StateNotifierProvider<ProductController, AsyncValue<void>>((ref) {
      return ProductController(ref, ref.watch(productRemoteDataSourceProvider));
    });

class ProductController extends StateNotifier<AsyncValue<void>> {
  ProductController(this._ref, this._productRemoteDataSource)
    : super(const AsyncData(null));

  final Ref _ref;
  final ProductRemoteDataSource _productRemoteDataSource;

  Future<void> createProduct({
    required String name,
    required String tagline,
    required String description,
    required String category,
    required List<String> tags,
    required String pricing,
    required String websiteUrl,
    required String demoUrl,
    required String githubUrl,
    required List<String> platforms,
    required String version,
    required List<File> screenshotFiles,
  }) async {
    state = const AsyncLoading();

    try {
      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found.');
      }

      await _productRemoteDataSource.createProduct(
        profile: profile,
        name: name,
        tagline: tagline,
        description: description,
        category: category,
        tags: tags,
        pricing: pricing,
        websiteUrl: websiteUrl,
        demoUrl: demoUrl,
        githubUrl: githubUrl,
        platforms: platforms,
        version: version,
        screenshotFiles: screenshotFiles,
      );

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.updateProduct(product);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> archiveProduct(String productId) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.archiveProduct(productId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> unlistProduct(String productId) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.unlistProduct(productId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> makeProductPublic(String productId) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.makeProductPublic(productId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleSaveProduct(String productId) async {
    final user = _ref.read(currentUserProvider);

    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.toggleSaveProduct(
        productId: productId,
        uid: user.uid,
      );

      _ref.invalidate(productSaveStateProvider(productId));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
