import 'package:cloud_firestore/cloud_firestore.dart';

class ProductScreenshotModel {
  final String url;
  final int order;

  const ProductScreenshotModel({
    required this.url,
    required this.order,
  });

  factory ProductScreenshotModel.fromMap(Map<String, dynamic> map) {
    return ProductScreenshotModel(
      url: map['url'] as String? ?? '',
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'order': order,
    };
  }
}

class ProductModel {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String ownerRole;
  final String? ownerAvatarUrl;

  final String name;
  final String tagline;
  final String description;
  final String category;
  final List<String> tags;

  final String pricing;
  final String websiteUrl;
  final String demoUrl;
  final String githubUrl;
  final List<String> platforms;

  final List<ProductScreenshotModel> screenshots;

  final String version;
  final DateTime? launchDate;

  final String visibility;
  final String status;

  final int savesCount;
  final int likesCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerRole,
    required this.ownerAvatarUrl,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.tags,
    required this.pricing,
    required this.websiteUrl,
    required this.demoUrl,
    required this.githubUrl,
    required this.platforms,
    required this.screenshots,
    required this.version,
    required this.launchDate,
    required this.visibility,
    required this.status,
    required this.savesCount,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ProductModel(
      id: data['id'] as String? ?? doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerRole: data['ownerRole'] as String? ?? '',
      ownerAvatarUrl: data['ownerAvatarUrl'] as String?,
      name: data['name'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      pricing: data['pricing'] as String? ?? '',
      websiteUrl: data['websiteUrl'] as String? ?? '',
      demoUrl: data['demoUrl'] as String? ?? '',
      githubUrl: data['githubUrl'] as String? ?? '',
      platforms: List<String>.from(data['platforms'] ?? []),
      screenshots: ((data['screenshots'] as List?) ?? [])
          .map(
            (item) => ProductScreenshotModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      version: data['version'] as String? ?? '',
      launchDate: (data['launchDate'] as Timestamp?)?.toDate(),
      visibility: data['visibility'] as String? ?? 'public',
      status: data['status'] as String? ?? 'active',
      savesCount: data['savesCount'] as int? ?? 0,
      likesCount: data['likesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerRole': ownerRole,
      'ownerAvatarUrl': ownerAvatarUrl,
      'name': name,
      'tagline': tagline,
      'description': description,
      'category': category,
      'tags': tags,
      'pricing': pricing,
      'websiteUrl': websiteUrl,
      'demoUrl': demoUrl,
      'githubUrl': githubUrl,
      'platforms': platforms,
      'screenshots': screenshots.map((item) => item.toMap()).toList(),
      'version': version,
      'launchDate': launchDate == null ? null : Timestamp.fromDate(launchDate!),
      'visibility': visibility,
      'status': status,
      'savesCount': savesCount,
      'likesCount': likesCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'tagline': tagline,
      'description': description,
      'category': category,
      'tags': tags,
      'pricing': pricing,
      'websiteUrl': websiteUrl,
      'demoUrl': demoUrl,
      'githubUrl': githubUrl,
      'platforms': platforms,
      'screenshots': screenshots.map((item) => item.toMap()).toList(),
      'version': version,
      'launchDate': launchDate == null ? null : Timestamp.fromDate(launchDate!),
      'visibility': visibility,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? name,
    String? tagline,
    String? description,
    String? category,
    List<String>? tags,
    String? pricing,
    String? websiteUrl,
    String? demoUrl,
    String? githubUrl,
    List<String>? platforms,
    List<ProductScreenshotModel>? screenshots,
    String? version,
    DateTime? launchDate,
    String? visibility,
    String? status,
  }) {
    return ProductModel(
      id: id,
      ownerUid: ownerUid,
      ownerName: ownerName,
      ownerRole: ownerRole,
      ownerAvatarUrl: ownerAvatarUrl,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      pricing: pricing ?? this.pricing,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      demoUrl: demoUrl ?? this.demoUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      platforms: platforms ?? this.platforms,
      screenshots: screenshots ?? this.screenshots,
      version: version ?? this.version,
      launchDate: launchDate ?? this.launchDate,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      savesCount: savesCount,
      likesCount: likesCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}