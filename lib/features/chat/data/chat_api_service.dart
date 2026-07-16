import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/chat_message.dart';

class ChatApiException implements Exception {
  const ChatApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChatApiService {
  ChatApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.chat,
        data: <String, dynamic>{
          'message': message,
          'history': history
              .where((ChatMessage item) => !item.isWelcome)
              .toList()
              .reversed
              .take(20)
              .toList()
              .reversed
              .map((ChatMessage item) => item.toHistoryJson())
              .toList(),
        },
      );

      final dynamic body = response.data;
      final dynamic data = body is Map<String, dynamic> ? body['data'] : null;
      final dynamic reply = data is Map<String, dynamic>
          ? data['reply']
          : body is Map<String, dynamic>
          ? body['reply']
          : null;

      if (reply is String && reply.trim().isNotEmpty) {
        return reply.trim();
      }
      throw const ChatApiException('Trợ lý chưa gửi được nội dung trả lời.');
    } on DioException catch (error) {
      throw ChatApiException(_messageFromDio(error));
    }
  }

  String _messageFromDio(DioException error) {
    final dynamic body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final dynamic serverMessage = body['message'];
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
        return 'Đã có lỗi khi gửi câu hỏi. Bạn hãy thử lại.';
    }
  }
}
