import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

final Provider<ChatRemoteDataSource> chatRemoteDataSourceProvider =
    Provider<ChatRemoteDataSource>((Ref ref) {
      return ChatRemoteDataSourceImpl(ref.watch(authDioProvider));
    });

final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((Ref ref) {
      return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
    });

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatNotifier(this._repository) : super(const ChatState()) {
    reset();
  }

  static const String _welcomeText =
      'Chào bạn! Mình là Lingua, trợ lý học tiếng Anh của bạn. '
      'Hôm nay bạn muốn luyện từ vựng, ngữ pháp hay phát âm?';

  void reset() {
    state = ChatState(
      messages: <ChatMessage>[
        ChatMessage(
          role: ChatRole.assistant,
          text: _welcomeText,
          sentAt: DateTime.now(),
          isWelcome: true,
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final List<ChatMessage> history = List<ChatMessage>.of(state.messages);
    final ChatMessage userMessage = ChatMessage(
      role: ChatRole.user,
      text: trimmed,
      sentAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: <ChatMessage>[...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );

    await _requestReply(message: trimmed, history: history);
  }

  Future<void> retryLastMessage() async {
    if (state.isSending) return;
    final int userIndex = state.messages.lastIndexWhere(
      (ChatMessage message) => message.role == ChatRole.user,
    );
    if (userIndex < 0) return;

    state = state.copyWith(isSending: true, clearError: true);
    await _requestReply(
      message: state.messages[userIndex].text,
      history: state.messages.sublist(0, userIndex),
    );
  }

  Future<void> _requestReply({
    required String message,
    required List<ChatMessage> history,
  }) async {
    try {
      final String reply = await _repository.sendMessage(
        message: message,
        history: history,
      );
      state = state.copyWith(
        messages: <ChatMessage>[
          ...state.messages,
          ChatMessage(
            role: ChatRole.assistant,
            text: reply,
            sentAt: DateTime.now(),
          ),
        ],
        isSending: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: _messageFromDio(error),
      );
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Đã có lỗi không mong muốn. Bạn hãy thử lại nhé.',
      );
    }
  }

  String _messageFromDio(DioException error) {
    final Object? body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final Object? serverMessage = body['message'];
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        return serverMessage;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Phản hồi đang mất nhiều thời gian. Bạn hãy thử lại nhé.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối tới máy chủ. Hãy kiểm tra mạng và địa chỉ API.';
      default:
        final Object? errorPayload = error.error;
        if (errorPayload is String && errorPayload.trim().isNotEmpty) {
          return errorPayload;
        }
        return 'Đã có lỗi khi gửi câu hỏi. Bạn hãy thử lại.';
    }
  }
}

final StateNotifierProvider<ChatNotifier, ChatState> chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((Ref ref) {
      return ChatNotifier(ref.watch(chatRepositoryProvider));
    });
