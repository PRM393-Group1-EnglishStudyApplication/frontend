import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/core/notifications/deep_link.dart';
import 'package:prm_frontend/features/notifications/data/models/reminder_settings_model.dart';

void main() {
  group('parseDeepLink', () {
    test('doc route learn', () {
      final PendingDeepLink? link = parseDeepLink(<String, dynamic>{
        'type': 'streak_reminder',
        'route': 'learn',
        'lesson_id': '',
      });

      expect(link, isNotNull);
      expect(link!.route, DeepLinkRoute.learn);
      expect(link.lessonId, isNull);
      expect(link.tabIndex, 0);
    });

    test('route practice tro ve tab Practice', () {
      final PendingDeepLink? link =
          parseDeepLink(<String, dynamic>{'type': 'streak_reminder', 'route': 'practice'});

      expect(link!.route, DeepLinkRoute.practice);
      expect(link.tabIndex, 1);
    });

    test('route lesson giu lai lesson_id', () {
      final PendingDeepLink? link = parseDeepLink(<String, dynamic>{
        'type': 'streak_reminder',
        'route': 'lesson',
        'lesson_id': '665f00000000000000000001',
      });

      expect(link!.route, DeepLinkRoute.lesson);
      expect(link.lessonId, '665f00000000000000000001');
    });

    test('route lesson thieu lesson_id thi ve tab Learn', () {
      final PendingDeepLink? link = parseDeepLink(<String, dynamic>{
        'type': 'streak_reminder',
        'route': 'lesson',
        'lesson_id': '',
      });

      expect(link!.route, DeepLinkRoute.learn);
      expect(link.lessonId, isNull);
    });

    test('route la cua v2 (app chua biet) -> unknown, chi mo app', () {
      final PendingDeepLink? link =
          parseDeepLink(<String, dynamic>{'type': 'flashcards_due', 'route': 'flashcards'});

      expect(link!.route, DeepLinkRoute.unknown);
      expect(link.tabIndex, isNull);
    });

    test('payload rong -> khong co gi de dieu huong', () {
      expect(parseDeepLink(null), isNull);
      expect(parseDeepLink(<String, dynamic>{}), isNull);
    });
  });

  group('deep link payload cua local notification', () {
    test('ma hoa roi giai ma lai giu nguyen dich den', () {
      final String payload = encodeDeepLinkPayload(<String, dynamic>{
        'type': 'streak_reminder',
        'route': 'lesson',
        'lesson_id': 'abc123',
      });

      final PendingDeepLink? link = decodeDeepLinkPayload(payload);

      expect(link!.route, DeepLinkRoute.lesson);
      expect(link.lessonId, 'abc123');
    });

    test('payload hong hoac rong -> null, khong nem loi', () {
      expect(decodeDeepLinkPayload(null), isNull);
      expect(decodeDeepLinkPayload(''), isNull);
      expect(decodeDeepLinkPayload('{khong-phai-json'), isNull);
    });
  });

  group('ReminderSettingsModel', () {
    test('doc JSON tu backend', () {
      final ReminderSettingsModel model = ReminderSettingsModel.fromJson(<String, dynamic>{
        'enabled': true,
        'time': '19:30',
        'days': <dynamic>[1, 3, 5],
        'tz_offset_minutes': 420,
      });

      expect(model.enabled, isTrue);
      expect(model.hour, 19);
      expect(model.minute, 30);
      expect(model.days, <int>[1, 3, 5]);
      expect(model.tzOffsetMinutes, 420);
    });

    test('ban ghi cu thieu tz_offset_minutes -> hieu la UTC', () {
      final ReminderSettingsModel model = ReminderSettingsModel.fromJson(<String, dynamic>{
        'enabled': false,
        'time': '19:00',
      });

      expect(model.tzOffsetMinutes, 0);
      expect(model.days, isEmpty);
    });

    test('toJson gui dung khoa backend mong doi', () {
      const ReminderSettingsModel model = ReminderSettingsModel(
        enabled: true,
        time: '08:05',
        days: <int>[],
        tzOffsetMinutes: 420,
      );

      expect(model.toJson(), <String, dynamic>{
        'enabled': true,
        'time': '08:05',
        'days': <int>[],
        'tz_offset_minutes': 420,
      });
    });
  });
}
