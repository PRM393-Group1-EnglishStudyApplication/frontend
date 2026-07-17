import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio _dio;

  ChatRemoteDataSourceImpl(this._dio);

  // Backend caps history at 20 turns; only send the most recent ones.
  static const int _maxHistory = 20;

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    final List<Map<String, dynamic>> historyPayload = history
        .where((ChatMessage item) => !item.isWelcome)
        .map((ChatMessage item) => ChatMessageModel.fromEntity(item).toHistoryJson())
        .toList();

    final List<Map<String, dynamic>> trimmedHistory =
        historyPayload.length > _maxHistory
        ? historyPayload.sublist(historyPayload.length - _maxHistory)
        : historyPayload;

    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/chat',
      data: <String, dynamic>{
        'message': message,
        'history': trimmedHistory,
      },
    );

    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body from server.',
      );
    }

    final ApiResponse<Map<String, dynamic>> apiResponse =
        ApiResponse<Map<String, dynamic>>.fromJson(
          response.data as Map<String, dynamic>,
          (Object? json) => json as Map<String, dynamic>,
        );

    if (!apiResponse.success || apiResponse.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Server returned an error.',
      );
    }

    final Object? reply = apiResponse.data!['reply'];
    if (reply is String && reply.trim().isNotEmpty) {
      return reply.trim();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Trợ lý chưa gửi được nội dung trả lời.',
    );
  }
}
