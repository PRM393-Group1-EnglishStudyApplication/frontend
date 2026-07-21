import '../../domain/entities/reminder_settings.dart';

class ReminderSettingsModel extends ReminderSettings {
  const ReminderSettingsModel({
    required super.enabled,
    required super.time,
    required super.days,
    required super.tzOffsetMinutes,
  });

  factory ReminderSettingsModel.fromJson(Map<String, dynamic> json) {
    final Object? rawDays = json['days'];
    return ReminderSettingsModel(
      enabled: json['enabled'] as bool? ?? false,
      time: json['time'] as String? ?? '19:00',
      days: rawDays is List
          ? rawDays.map((Object? day) => (day as num?)?.toInt() ?? 0).toList()
          : const <int>[],
      // Bản ghi tạo trước khi backend có field này sẽ thiếu -> hiểu là UTC (0),
      // đúng bằng cách backend diễn giải chúng.
      tzOffsetMinutes: (json['tz_offset_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'time': time,
        'days': days,
        'tz_offset_minutes': tzOffsetMinutes,
      };
}
