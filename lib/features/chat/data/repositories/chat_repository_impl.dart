import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) {
    return _remoteDataSource.sendMessage(message: message, history: history);
  }
}
