import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../models/reminder_settings_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> registerDeviceToken({required String token, required String platform}) {
    return _remoteDataSource.registerDeviceToken(token: token, platform: platform);
  }

  @override
  Future<void> unregisterDeviceToken(String token) {
    return _remoteDataSource.unregisterDeviceToken(token);
  }

  @override
  Future<ReminderSettings> getReminderSettings() {
    return _remoteDataSource.getReminderSettings();
  }

  @override
  Future<ReminderSettings> updateReminderSettings(ReminderSettings settings) {
    return _remoteDataSource.updateReminderSettings(
      ReminderSettingsModel(
        enabled: settings.enabled,
        time: settings.time,
        days: settings.days,
        tzOffsetMinutes: settings.tzOffsetMinutes,
      ),
    );
  }

  @override
  Future<void> sendTestNotification() => _remoteDataSource.sendTestNotification();
}
