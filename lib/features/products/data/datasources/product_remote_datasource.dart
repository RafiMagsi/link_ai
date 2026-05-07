import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../profile/data/models/profile_model.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _products {
    return _firestore.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _productSaves {
    return _firestore.collection('productSaves');
  }

  Stream<List<ProductModel>> watchPublicProducts({int limit = 50}) {
    return _products
        .where('visibility', isEqualTo: 'public')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map(ProductModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint('Error parsing public products: $error\n$stackTrace');
            return [];
          }
        });
  }

  Stream<List<ProductModel>> watchMyProducts(String uid, {int limit = 100}) {
    return _products
        .where('ownerUid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map(ProductModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing user products for $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return _products.doc(productId).snapshots().map((doc) {
      try {
        if (!doc.exists) return null;
        return ProductModel.fromFirestore(doc);
      } catch (error, stackTrace) {
        debugPrint('Error parsing product $productId: $error\n$stackTrace');
        return null;
      }
    });
  }

  Future<void> createProduct({
    required ProfileModel profile,
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
    try {
      final productId = _products.doc().id;

      final uploadedScreenshots = <ProductScreenshotModel>[];

      for (var i = 0; i < screenshotFiles.length; i++) {
        try {
          final file = screenshotFiles[i];
          final fileName = '${_uuid.v4()}.jpg';

          final ref = _storage.ref().child(
            'productMedia/${profile.uid}/$productId/$fileName',
          );

          await ref
              .putFile(
                file,
                SettableMetadata(
                  contentType: 'image/jpeg',
                  customMetadata: {'uid': profile.uid, 'productId': productId},
                ),
              )
              .timeout(const Duration(seconds: 30));

          final url = await ref.getDownloadURL().timeout(
            const Duration(seconds: 10),
          );

          uploadedScreenshots.add(ProductScreenshotModel(url: url, order: i));
        } catch (error, stackTrace) {
          debugPrint('Error uploading screenshot $i: $error\n$stackTrace');
          rethrow;
        }
      }

      final product = ProductModel(
        id: productId,
        ownerUid: profile.uid,
        ownerName: profile.name,
        ownerRole: profile.role,
        ownerAvatarUrl: profile.avatarUrl,
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
        screenshots: uploadedScreenshots,
        version: version,
        launchDate: null,
        visibility: 'public',
        status: 'active',
        savesCount: 0,
        likesCount: 0,
        createdAt: null,
        updatedAt: null,
      );

      await _products
          .doc(productId)
          .set(product.toCreateMap())
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error creating product: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _products
          .doc(product.id)
          .update(product.toUpdateMap())
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error updating product ${product.id}: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> archiveProduct(String productId) async {
    try {
      await _products
          .doc(productId)
          .update({
            'status': 'archived',
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error archiving product $productId: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> unlistProduct(String productId) async {
    try {
      await _products
          .doc(productId)
          .update({
            'visibility': 'unlisted',
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error unlisting product $productId: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> makeProductPublic(String productId) async {
    try {
      await _products
          .doc(productId)
          .update({
            'visibility': 'public',
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error making product $productId public: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<bool> hasSavedProduct({
    required String productId,
    required String uid,
  }) async {
    try {
      final doc = await _productSaves
          .doc('${productId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if product $productId saved by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Stream<List<String>> watchSavedProductIdsByUser(
    String uid, {
    int limit = 50,
  }) {
    return _productSaves
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => (doc.data()['productId'] as String?) ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing saved product IDs for user $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Future<void> toggleSaveProduct({
    required String productId,
    required String uid,
  }) async {
    try {
      final saveId = '${productId}_$uid';
      final saveRef = _productSaves.doc(saveId);
      final productRef = _products.doc(productId);

      await _firestore
          .runTransaction((transaction) async {
            final saveSnapshot = await transaction.get(saveRef);

            if (saveSnapshot.exists) {
              transaction.delete(saveRef);
              transaction.update(productRef, {
                'savesCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(saveRef, {
                'id': saveId,
                'productId': productId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(productRef, {
                'savesCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling save on product $productId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<List<ProductModel>> searchProducts(
    String query, {
    int limit = 20,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _products
          .where('visibility', isEqualTo: 'public')
          .where('status', isEqualTo: 'active')
          .limit(limit + 50)
          .get()
          .timeout(const Duration(seconds: 10));

      final results = snapshot.docs
          .map((doc) {
            try {
              return ProductModel.fromFirestore(doc);
            } catch (error, stackTrace) {
              debugPrint(
                'Error parsing product in search: $error\n$stackTrace',
              );
              return null;
            }
          })
          .whereType<ProductModel>()
          .where((product) {
            final nameMatch = product.name.toLowerCase().contains(queryLower);
            final categoryMatch = product.category.toLowerCase().contains(
              queryLower,
            );
            final tagsMatch = product.tags.any(
              (tag) => tag.toLowerCase().contains(queryLower),
            );

            return nameMatch || categoryMatch || tagsMatch;
          })
          .take(limit)
          .toList();

      return results;
    } catch (error, stackTrace) {
      debugPrint('Error searching products: $error\n$stackTrace');
      return [];
    }
  }
}
