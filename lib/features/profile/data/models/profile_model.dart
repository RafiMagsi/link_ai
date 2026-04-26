import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String bio;
  final String location;
  final String? avatarUrl;
  final List<String> skills;
  final List<String> tools;
  final String building;
  final String need;
  final String wantToMeet;
  final Map<String, String> links;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.bio,
    required this.location,
    required this.avatarUrl,
    required this.skills,
    required this.tools,
    required this.building,
    required this.need,
    required this.wantToMeet,
    required this.links,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.empty({
    required String uid,
    required String email,
    String name = '',
  }) {
    return ProfileModel(
      uid: uid,
      email: email,
      name: name,
      role: '',
      bio: '',
      location: '',
      avatarUrl: null,
      skills: const [],
      tools: const [],
      building: '',
      need: '',
      wantToMeet: '',
      links: const {
        'website': '',
        'linkedin': '',
        'github': '',
        'x': '',
      },
      createdAt: null,
      updatedAt: null,
    );
  }

  factory ProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ProfileModel(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      location: data['location'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      skills: List<String>.from(data['skills'] ?? []),
      tools: List<String>.from(data['tools'] ?? []),
      building: data['building'] as String? ?? '',
      need: data['need'] as String? ?? '',
      wantToMeet: data['wantToMeet'] as String? ?? '',
      links: Map<String, String>.from(data['links'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'bio': bio,
      'location': location,
      'avatarUrl': avatarUrl,
      'skills': skills,
      'tools': tools,
      'building': building,
      'need': need,
      'wantToMeet': wantToMeet,
      'links': links,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'role': role,
      'bio': bio,
      'location': location,
      'avatarUrl': avatarUrl,
      'skills': skills,
      'tools': tools,
      'building': building,
      'need': need,
      'wantToMeet': wantToMeet,
      'links': links,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProfileModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? bio,
    String? location,
    String? avatarUrl,
    List<String>? skills,
    List<String>? tools,
    String? building,
    String? need,
    String? wantToMeet,
    Map<String, String>? links,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      skills: skills ?? this.skills,
      tools: tools ?? this.tools,
      building: building ?? this.building,
      need: need ?? this.need,
      wantToMeet: wantToMeet ?? this.wantToMeet,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}