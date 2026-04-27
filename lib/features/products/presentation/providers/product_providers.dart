import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/errors/error_handler.dart';
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
      // Validate input
      if (name.trim().isEmpty) {
        throw ValidationError('Product name cannot be empty');
      }
      if (name.length > 100) {
        throw ValidationError('Product name cannot exceed 100 characters');
      }

      if (description.trim().isEmpty) {
        throw ValidationError('Product description cannot be empty');
      }
      if (description.length > 2000) {
        throw ValidationError('Product description cannot exceed 2000 characters');
      }

      if (category.trim().isEmpty) {
        throw ValidationError('Please select a product category');
      }

      if (tags.isEmpty) {
        throw ValidationError('Please add at least one tag');
      }

      if (tags.length > 10) {
        throw ValidationError('Maximum 10 tags allowed');
      }

      // Validate screenshots
      const maxScreenshotSize = 10 * 1024 * 1024; // 10MB per screenshot
      const maxTotalScreenshotsSize = 50 * 1024 * 1024; // 50MB total
      int totalSize = 0;

      if (screenshotFiles.isEmpty) {
        throw ValidationError('Please add at least one product screenshot');
      }

      if (screenshotFiles.length > 10) {
        throw ValidationError('Maximum 10 screenshots allowed');
      }

      for (final file in screenshotFiles) {
        final fileSize = file.lengthSync();
        if (fileSize > maxScreenshotSize) {
          throw FileSizeError('Screenshot size exceeds 10MB limit');
        }
        totalSize += fileSize;
      }

      if (totalSize > maxTotalScreenshotsSize) {
        throw FileSizeError('Total screenshot size exceeds 50MB limit');
      }

      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found. Please log in again.');
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
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('Product creation timed out'),
      );

      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      print('Validation error creating product: $error');
      state = AsyncError(error, stackTrace);
    } on FileSizeError catch (error, stackTrace) {
      print('File size error creating product: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout creating product: $error');
      state = AsyncError(
        Exception('Product creation took too long. Please check your connection and try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error creating product: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    state = const AsyncLoading();

    try {
      // Validate product data
      if (product.name.trim().isEmpty) {
        throw ValidationError('Product name cannot be empty');
      }

      if (product.description.trim().isEmpty) {
        throw ValidationError('Product description cannot be empty');
      }

      await _productRemoteDataSource.updateProduct(product).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Product update timed out'),
      );
      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      print('Validation error updating product: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout updating product: $error');
      state = AsyncError(
        Exception('Product update took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error updating product: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> archiveProduct(String productId) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.archiveProduct(productId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Archive operation timed out'),
      );
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout archiving product: $error');
      state = AsyncError(
        Exception('Archive operation took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error archiving product: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> unlistProduct(String productId) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.unlistProduct(productId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Unlist operation timed out'),
      );
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout unlisting product: $error');
      state = AsyncError(
        Exception('Unlist operation took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error unlisting product: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> makeProductPublic(String productId) async {
    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.makeProductPublic(productId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Publish operation timed out'),
      );
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout publishing product: $error');
      state = AsyncError(
        Exception('Publish operation took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error publishing product: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleSaveProduct(String productId) async {
    final user = _ref.read(currentUserProvider);

    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to save products.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _productRemoteDataSource.toggleSaveProduct(
        productId: productId,
        uid: user.uid,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Save operation timed out'),
      );

      _ref.invalidate(productSaveStateProvider(productId));

      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout toggling save: $error');
      state = AsyncError(
        Exception('Operation took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error toggling save: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }
}
