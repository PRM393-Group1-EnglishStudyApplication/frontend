import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  // Phải xong trước runApp để bắt được thông báo đã mở app từ trạng thái tắt hẳn.
  // Tự nuốt lỗi bên trong nên không cần try-catch ở đây (NFR-3).
  await PushService.instance.initialize();
  runApp(
    const ProviderScope(
      child: PrmApp(),
    ),
  );
}
