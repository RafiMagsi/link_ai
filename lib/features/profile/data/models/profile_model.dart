import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  final String collaborationIntent;
  final String projectStage;
  final List<String> lookingFor;
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
    required this.collaborationIntent,
    required this.projectStage,
    required this.lookingFor,
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
      collaborationIntent: 'open_to_collaborate',
      projectStage: 'mvp',
      lookingFor: const [],
      links: const {'website': '', 'linkedin': '', 'github': '', 'x': ''},
      createdAt: null,
      updatedAt: null,
    );
  }

  factory ProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data() ?? {};

      return ProfileModel(
        uid: _safeString(data['uid'], fallback: doc.id),
        email: _safeEmail(data['email']),
        name: _safeString(data['name']),
        role: _safeString(data['role']),
        bio: _safeString(data['bio']),
        location: _safeString(data['location']),
        avatarUrl: _safeUrl(data['avatarUrl']),
        skills: _safeStringList(data['skills']),
        tools: _safeStringList(data['tools']),
        building: _safeString(data['building']),
        need: _safeString(data['need']),
        wantToMeet: _safeString(data['wantToMeet']),
        collaborationIntent: _safeString(
          data['collaborationIntent'],
          fallback: 'open_to_collaborate',
        ),
        projectStage: _safeString(data['projectStage'], fallback: 'mvp'),
        lookingFor: _safeStringList(data['lookingFor']),
        links: _safeStringMap(data['links']),
        createdAt: _safeTimestamp(data['createdAt']),
        updatedAt: _safeTimestamp(data['updatedAt']),
      );
    } catch (e) {
      debugPrint('Error parsing ProfileModel from Firestore: $e');
      // Return empty profile with valid uid
      return ProfileModel.empty(uid: doc.id, email: '', name: '');
    }
  }

  static String _safeString(dynamic value, {String fallback = ''}) {
    try {
      if (value == null) return fallback;
      if (value is String) return value.trim();
      return value.toString().trim();
    } catch (e) {
      return fallback;
    }
  }

  static String _safeEmail(dynamic value) {
    try {
      if (value == null) return '';
      final email = (value as String).trim().toLowerCase();
      // Basic email validation
      if (_isValidEmail(email)) {
        return email;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static bool _isValidEmail(String email) {
    try {
      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      return regex.hasMatch(email) && email.length <= 254;
    } catch (e) {
      return false;
    }
  }

  static String? _safeUrl(dynamic value) {
    try {
      if (value == null) return null;
      final url = (value as String).trim();
      if (url.isEmpty) return null;
      Uri.parse(url); // Validate URL format
      return url;
    } catch (e) {
      return null;
    }
  }

  static List<String> _safeStringList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is List) {
        return value
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing string list: $e');
      return [];
    }
  }

  static Map<String, String> _safeStringMap(dynamic value) {
    try {
      if (value == null) return {};
      if (value is Map) {
        final result = <String, String>{};
        value.forEach((key, val) {
          try {
            final k = (key as String).trim();
            final v = (val as String?)?.trim() ?? '';
            if (k.isNotEmpty) {
              result[k] = v;
            }
          } catch (e) {
            debugPrint('Error processing map entry: $e');
          }
        });
        return result;
      }
      return {};
    } catch (e) {
      debugPrint('Error parsing string map: $e');
      return {};
    }
  }

  static DateTime? _safeTimestamp(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return null;
    }
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
      'collaborationIntent': collaborationIntent,
      'projectStage': projectStage,
      'lookingFor': lookingFor,
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
      'collaborationIntent': collaborationIntent,
      'projectStage': projectStage,
      'lookingFor': lookingFor,
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
    String? collaborationIntent,
    String? projectStage,
    List<String>? lookingFor,
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
      collaborationIntent: collaborationIntent ?? this.collaborationIntent,
      projectStage: projectStage ?? this.projectStage,
      lookingFor: lookingFor ?? this.lookingFor,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
