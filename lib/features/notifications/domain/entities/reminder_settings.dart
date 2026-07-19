/// Cấu hình nhắc học của người dùng, lấy từ `GET /api/notifications/reminders/me`.
class ReminderSettings {
  final bool enabled;

  /// Giờ nhắc dạng `HH:mm` theo **giờ địa phương** của thiết bị.
  final String time;

  /// 0=CN ... 6=Thứ 7. Rỗng nghĩa là nhắc mọi ngày.
  final List<int> days;

  /// Số phút cộng vào UTC để ra giờ địa phương (Việt Nam = 420).
  /// Backend cần giá trị này để so giờ đúng theo múi giờ người dùng.
  final int tzOffsetMinutes;

  const ReminderSettings({
    required this.enabled,
    required this.time,
    required this.days,
    required this.tzOffsetMinutes,
  });

  /// Giá trị hiển thị trước khi gọi API xong, và khi API lỗi.
  factory ReminderSettings.fallback() => ReminderSettings(
        enabled: false,
        time: '19:00',
        days: const <int>[],
        tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
      );

  int get hour => int.tryParse(time.split(':').first) ?? 19;

  int get minute => int.tryParse(time.split(':').last) ?? 0;

  ReminderSettings copyWith({
    bool? enabled,
    String? time,
    List<int>? days,
    int? tzOffsetMinutes,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      days: days ?? this.days,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    );
  }
}
