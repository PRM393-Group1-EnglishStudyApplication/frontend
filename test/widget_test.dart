import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prm_frontend/app/app.dart';
import 'package:prm_frontend/features/chat/data/chat_api_service.dart';
import 'package:prm_frontend/features/chat/domain/chat_message.dart';
import 'package:prm_frontend/features/chat/presentation/chat_page.dart';

void main() {
  testWidgets('Render AI chat page', (WidgetTester tester) async {
    await tester.pumpWidget(const PrmApp());

    expect(find.text('Lingua AI'), findsOneWidget);
    expect(find.text('Sẵn sàng hỗ trợ bạn'), findsOneWidget);
    expect(find.text('GỢI Ý CHO BẠN'), findsOneWidget);
    expect(find.text('Hỏi Lingua về tiếng Anh...'), findsOneWidget);
  });

  testWidgets('Send a suggested prompt and render AI reply', (
    WidgetTester tester,
  ) async {
    final _FakeChatApiService service = _FakeChatApiService();
    await tester.pumpWidget(
      MaterialApp(home: ChatPage(chatApiService: service)),
    );

    await tester.tap(find.text('Phân biệt giúp mình “make” và “do”'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Make là tạo ra, còn do là thực hiện.'), findsOneWidget);
    expect(service.lastMessage, 'Phân biệt giúp mình “make” và “do”');
    expect(service.lastHistory.single.isWelcome, isTrue);
  });
}

class _FakeChatApiService extends ChatApiService {
  String? lastMessage;
  List<ChatMessage> lastHistory = <ChatMessage>[];

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    lastMessage = message;
    lastHistory = history;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return 'Make là tạo ra, còn do là thực hiện.';
  }
}
