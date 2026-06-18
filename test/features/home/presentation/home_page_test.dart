import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/auth/domain/entities/app_user.dart';
import 'package:prm_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/home/presentation/home_page.dart';
import 'package:prm_frontend/features/hearts/domain/entities/heart_status.dart';
import 'package:prm_frontend/features/hearts/domain/repositories/heart_repository.dart';
import 'package:prm_frontend/features/hearts/presentation/providers/heart_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/mock_http_service.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser? user;
  Object? exception;
  int callCount = 0;

  @override
  Future<AppUser> getCurrentUser() async {
    callCount++;
    if (exception != null) {
      throw exception!;
    }
    if (user != null) {
      return user!;
    }
    throw Exception('No fake user provided');
  }
}

class FakeHeartRepository implements HeartRepository {
  HeartStatus hearts = const HeartStatus(
    userId: 'user_123',
    currentHearts: 5,
    maxHearts: 5,
  );

  @override
  Future<HeartStatus> getMyHearts() async => hearts;

  @override
  Future<HeartStatus> refillHearts() async {
    hearts = hearts.copyWith(currentHearts: hearts.maxHearts);
    return hearts;
  }
}

class MockDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String path = options.path;
    if (path.endsWith('/api/courses')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': [
            {
              '_id': 'course_123',
              'title': 'Vietnamese',
              'description': 'Learn Vietnamese',
              'target_level': 'beginner',
            }
          ],
        },
      ));
      return;
    }
    if (path.contains('/api/courses/course_123/units') || path.endsWith('/units')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': [
            {
              '_id': 'unit_123',
              'course_id': 'course_123',
              'title': 'Unit 1',
              'description': 'Basics – Greetings & Numbers',
              'order_index': 1,
            }
          ],
        },
      ));
      return;
    }
    if (path.contains('/api/units/unit_123/lessons') || path.endsWith('/lessons')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': [
            {
              '_id': 'lesson_1',
              'unit_id': 'unit_123',
              'title': 'Basics 1',
              'order_index': 1,
              'xp_reward': 10,
            },
            {
              '_id': 'lesson_2',
              'unit_id': 'unit_123',
              'title': 'Basics 2',
              'order_index': 2,
              'xp_reward': 10,
            }
          ],
        },
      ));
      return;
    }
    if (path.contains('/api/hearts/me')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': {
            'user_id': 'user_123',
            'current_hearts': 5,
            'max_hearts': 5,
          },
        },
      ));
      return;
    }
    if (path.contains('/api/leaderboard/me')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': {
            '_id': 'lb_1',
            'user_id': 'user_123',
            'week_start_date': '2026-06-15',
            'xp': 450,
            'rank_position': 1,
          },
        },
      ));
      return;
    }
    if (path.contains('/api/leaderboard')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': [
            {
              '_id': 'lb_1',
              'user_id': 'user_123',
              'week_start_date': '2026-06-15',
              'xp': 450,
              'rank_position': 1,
              'user': {
                '_id': 'user_123',
                'full_name': 'Jane Doe',
                'email': 'jane.doe@example.com',
                'total_xp': 450,
                'current_level': 'beginner',
                'streak_count': 5,
              }
            },
            {
              '_id': 'lb_2',
              'user_id': 'user_456',
              'week_start_date': '2026-06-15',
              'xp': 300,
              'rank_position': 2,
              'user': {
                '_id': 'user_456',
                'full_name': 'John Doe',
                'email': 'john.doe@example.com',
                'total_xp': 300,
                'current_level': 'beginner',
                'streak_count': 2,
              }
            }
          ],
        },
      ));
      return;
    }
    if (path.contains('/api/achievements/me') || path.contains('/api/achievements')) {
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'success': true,
          'message': 'success',
          'data': <dynamic>[],
        },
      ));
      return;
    }
    handler.next(options);
  }
}

void main() {
  const testUser = AppUser(
    id: 'user_123',
    email: 'jane.doe@example.com',
    fullName: 'Jane Doe',
    avatarUrl: '',
    totalXp: 450,
    currentLevel: 'beginner',
    streakCount: 5,
  );

  late FakeAuthRepository fakeAuthRepository;
  late FakeHeartRepository fakeHeartRepository;
  late Dio mockDio;

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'CLERK_PUBLISHABLE_KEY=pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==\nAPI_BASE_URL=https://backend-6i8r.onrender.com',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'active_course_id': 'course_123',
      'completed_lesson_lesson_1': true,
    });
    fakeAuthRepository = FakeAuthRepository()..user = testUser;
    fakeHeartRepository = FakeHeartRepository();
    
    mockDio = Dio(
      BaseOptions(
        baseUrl: 'https://backend-6i8r.onrender.com',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    mockDio.interceptors.add(MockDioInterceptor());
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        heartRepositoryProvider.overrideWithValue(fakeHeartRepository),
        clerkTokenProvider.overrideWith((ref) => 'fake_token'),
        authDioProvider.overrideWithValue(mockDio),
      ],
      child: ClerkAuth(
        config: TestClerkAuthConfig(
          publishableKey: 'pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==',
          httpService: const MockHttpService(
            clientResponse: janeDoeClientResponse,
          ),
        ),
        child: const MaterialApp(home: HomePage()),
      ),
    );
  }

  Future<void> pumpTestWidget(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    // Pump several frames with duration to resolve the entire async data loading chain
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('HomePage renders NavigationBar with four tabs', (
    WidgetTester tester,
  ) async {
    await pumpTestWidget(tester);

    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(navBarFinder);
    expect(navigationBar.destinations.length, 4);

    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Practice'), findsWidgets);
    expect(find.text('Leaderboard'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('HomePage initial state shows Learn tab content', (
    WidgetTester tester,
  ) async {
    await pumpTestWidget(tester);

    expect(find.text('Vietnamese'), findsOneWidget);

    // Verify stats pills values: streak (5) and total XP (450)
    expect(find.text('5'), findsWidgets); // Streak and Hearts
    expect(find.text('450'), findsOneWidget); // Diamonds/XP

    // Verify progress card details
    expect(find.text('CHƯƠNG HIỆN TẠI'), findsOneWidget);
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget); // 1 of 2 lessons completed

    // Scroll down to bring daily quests card into view
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify daily quests card
    expect(find.text('Nhiệm vụ hàng ngày'), findsOneWidget);
    expect(find.text('Học thêm 10 từ vựng mới'), findsOneWidget);
    expect(find.text('Đã hoàn thành 7/10'), findsOneWidget);
  });

  testWidgets('Tapping Leaderboard tab displays leaderboard list', (
    WidgetTester tester,
  ) async {
    await pumpTestWidget(tester);

    await tester.tap(find.text('Leaderboard'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Bạn (Bạn)'), findsWidgets);
  });

  testWidgets('Tapping Practice tab displays practice dashboard', (
    WidgetTester tester,
  ) async {
    await pumpTestWidget(tester);

    await tester.tap(find.text('Practice'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Luyện tập (Personal Insights)'), findsOneWidget);
    expect(find.text('Practice Streak'), findsOneWidget);
    expect(find.text('Từ vựng'), findsOneWidget);
    expect(find.text('Cần xem lại'), findsOneWidget);
  });

  testWidgets('Tapping Profile tab displays profile card and sign-out button', (
    WidgetTester tester,
  ) async {
    await pumpTestWidget(tester);

    await tester.tap(find.text('Profile'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(find.text('Chuỗi ngày'), findsOneWidget);
    expect(find.text('Tổng XP'), findsOneWidget);
  });
}
