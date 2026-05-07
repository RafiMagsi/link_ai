import 'package:cloud_functions/cloud_functions.dart';

class SnowChatMessagePayload {
  const SnowChatMessagePayload({required this.role, required this.text});

  final String role;
  final String text;

  Map<String, String> toMap() {
    return {'role': role, 'text': text};
  }
}

class SnowChatRemoteDataSource {
  SnowChatRemoteDataSource(this._functions);

  final FirebaseFunctions _functions;

  Future<String> sendMessage({
    required String message,
    required List<SnowChatMessagePayload> history,
  }) async {
    final callable = _functions.httpsCallable('snowAiResponse');
    final response = await callable.call<Map<String, dynamic>>({
      'message': message,
      'messages': history.map((item) => item.toMap()).toList(),
    });
    final data = response.data;
    final text = data['response'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Snow returned an empty response.');
    }
    return text.trim();
  }
}
