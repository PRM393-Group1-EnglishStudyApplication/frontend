import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/reminder_settings_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<void> registerDeviceToken({required String token, required String platform});

  Future<void> unregisterDeviceToken(String token);

  Future<ReminderSettingsModel> getReminderSettings();

  Future<ReminderSettingsModel> updateReminderSettings(ReminderSettingsModel settings);

  Future<void> sendTestNotification();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final Dio _dio;

  NotificationsRemoteDataSourceImpl(this._dio);

  @override
  Future<void> registerDeviceToken({required String token, required String platform}) async {
    await _dio.post<dynamic>(
      '/api/notifications/device-tokens',
      data: <String, dynamic>{'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    // Backend nhận token trong body của DELETE (không phải query param).
    await _dio.delete<dynamic>(
      '/api/notifications/device-tokens',
      data: <String, dynamic>{'token': token},
    );
  }

  @override
  Future<ReminderSettingsModel> getReminderSettings() async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/api/notifications/reminders/me');
    return _unwrap(response);
  }

  @override
  Future<ReminderSettingsModel> updateReminderSettings(ReminderSettingsModel settings) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      '/api/notifications/reminders/me',
      data: settings.toJson(),
    );
    return _unwrap(response);
  }

  @override
  Future<void> sendTestNotification() async {
    await _dio.post<dynamic>('/api/notifications/test', data: <String, dynamic>{});
  }

  ReminderSettingsModel _unwrap(Response<dynamic> response) {
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
        error: apiResponse.message.isNotEmpty ? apiResponse.message : 'Server returned an error.',
      );
    }

    return ReminderSettingsModel.fromJson(apiResponse.data!);
  }
}
