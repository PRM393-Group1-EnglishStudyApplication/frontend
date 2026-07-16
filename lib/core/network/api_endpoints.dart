class ApiEndpoints {
  // Android emulator reaches the development machine through 10.0.2.2.
  // Override for a physical device or production build with:
  // --dart-define=API_BASE_URL=https://your-api.example.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const String users = '/users';
  static const String chat = '/api/chat';

  const ApiEndpoints._();
}
