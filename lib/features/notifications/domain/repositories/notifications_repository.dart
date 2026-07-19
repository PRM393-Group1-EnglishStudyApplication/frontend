import '../entities/reminder_settings.dart';

abstract class NotificationsRepository {
  Future<void> registerDeviceToken({required String token, required String platform});

  Future<void> unregisterDeviceToken(String token);

  Future<ReminderSettings> getReminderSettings();

  Future<ReminderSettings> updateReminderSettings(ReminderSettings settings);

  Future<void> sendTestNotification();
}
