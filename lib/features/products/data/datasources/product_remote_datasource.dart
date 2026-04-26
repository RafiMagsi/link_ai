import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
        .map(
          (snapshot) => snapshot.docs.map(ProductModel.fromFirestore).toList(),
        );
  }

  Stream<List<ProductModel>> watchMyProducts(String uid, {int limit = 100}) {
    return _products
        .where('ownerUid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ProductModel.fromFirestore).toList(),
        );
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return _products.doc(productId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
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
    final productId = _products.doc().id;

    final uploadedScreenshots = <ProductScreenshotModel>[];

    for (var i = 0; i < screenshotFiles.length; i++) {
      final file = screenshotFiles[i];
      final fileName = '${_uuid.v4()}.jpg';

      final ref = _storage.ref().child(
        'productMedia/${profile.uid}/$productId/$fileName',
      );

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uid': profile.uid, 'productId': productId},
        ),
      );

      final url = await ref.getDownloadURL();

      uploadedScreenshots.add(ProductScreenshotModel(url: url, order: i));
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

    await _products.doc(productId).set(product.toCreateMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _products.doc(product.id).update(product.toUpdateMap());
  }

  Future<void> archiveProduct(String productId) async {
    await _products.doc(productId).update({
      'status': 'archived',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unlistProduct(String productId) async {
    await _products.doc(productId).update({
      'visibility': 'unlisted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> makeProductPublic(String productId) async {
    await _products.doc(productId).update({
      'visibility': 'public',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasSavedProduct({
    required String productId,
    required String uid,
  }) async {
    final doc = await _productSaves.doc('${productId}_$uid').get();
    return doc.exists;
  }

  Future<void> toggleSaveProduct({
    required String productId,
    required String uid,
  }) async {
    final saveId = '${productId}_$uid';
    final saveRef = _productSaves.doc(saveId);
    final productRef = _products.doc(productId);

    await _firestore.runTransaction((transaction) async {
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
    });
  }
}
