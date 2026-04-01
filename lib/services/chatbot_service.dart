import 'package:supabase_flutter/supabase_flutter.dart';

class ChatbotServiceException implements Exception {
  final String message;
  const ChatbotServiceException(this.message);

  @override
  String toString() => message;
}

Future<String> sendPromptToBot(String userMessage) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'chat-bot',
      body: {'prompt': userMessage},
    );

    final dynamic payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const ChatbotServiceException(
        'Invalid chatbot response payload.',
      );
    }

    if (payload['error'] is String && (payload['error'] as String).isNotEmpty) {
      throw ChatbotServiceException(payload['error'] as String);
    }

    final reply = payload['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const ChatbotServiceException(
        'Chatbot returned an empty response.',
      );
    }

    return reply;
  } on FunctionException catch (e) {
    final details = e.details;
    if (details is Map<String, dynamic> &&
        details['error'] is String &&
        (details['error'] as String).isNotEmpty) {
      throw ChatbotServiceException(details['error'] as String);
    }

    final message = e.toString();
    throw ChatbotServiceException(message);
  } catch (e) {
    if (e is ChatbotServiceException) rethrow;
    throw ChatbotServiceException(e.toString());
  }
}
