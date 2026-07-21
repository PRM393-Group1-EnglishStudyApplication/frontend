import '../entities/chat_message.dart';

abstract class ChatRepository {
  /// Sends [message] together with the prior [history] and returns the
  /// assistant's reply text.
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  });
}
