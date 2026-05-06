import 'package:cloud_functions/cloud_functions.dart';

import '../../../feed/data/models/post_model.dart';

class AiAssistRemoteDataSource {
  AiAssistRemoteDataSource(this._functions);

  final FirebaseFunctions _functions;

  Future<String> improveProfileText({
    required String field,
    required String name,
    required String role,
    required List<String> skills,
    required List<String> tools,
    required String building,
    required String need,
    required String currentText,
  }) async {
    final callable = _functions.httpsCallable('improveProfileText');
    final result = await callable.call({
      'field': field,
      'name': name,
      'role': role,
      'skills': skills,
      'tools': tools,
      'building': building,
      'need': need,
      'currentText': currentText,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['text'] as String? ?? '').trim();
  }

  Future<String> improvePostDraft({
    required PostIntent intent,
    required String text,
  }) async {
    final callable = _functions.httpsCallable('improvePostDraft');
    final result = await callable.call({'intent': intent.name, 'text': text});

    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['text'] as String? ?? '').trim();
  }

  Future<List<String>> suggestPostTags({
    required PostIntent intent,
    required String text,
  }) async {
    final callable = _functions.httpsCallable('suggestPostTags');
    final result = await callable.call({'intent': intent.name, 'text': text});

    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}
