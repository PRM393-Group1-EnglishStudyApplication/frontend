# Developer Agent Guide: Frontend Configuration & Architecture

Welcome! This guide explains the architecture, setup instructions, and testing requirements for this Flutter codebase.

## 1. Authentication Architecture

The application uses **Clerk** for user authentication and session management on the client side, coupled with a **MongoDB backend** that acts as the source of truth for user stats (XP, level, streak, etc.).

- **Non-Blocking Background Sync**:
  - Transition from `SignInScreen` to `HomePage` is **instant** upon Clerk login success.
  - Cached Clerk profile data (Name, Email, Image URL) from `ClerkAuth.userOf(context)` is displayed immediately.
  - User stats (XP, level, streak) are fetched asynchronously in the background via `currentUserProvider` calling the backend (`GET /api/auth/me`).
  - Scoped `Consumer` widgets wrap stats panels to display inline spinners or errors, ensuring the main layout remains fully interactive.

---

## 2. Environment Variables & Configurations

### Clerk Publishable Key

- **Format Constraint**: Clerk SDK parses and base64-decodes the domain suffix of the publishable key. Passing arbitrary placeholders (like `'pk_test_placeholder'`) will throw a `FormatException` during initialization, causing the app to hang.
- **Valid Test Key format**: `pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==` (which decodes to `clerk.prm.learning$`).

### Backend URL Configuration

- Ensure your local backend is running (typically on `http://localhost:5000` or the configured dev/production endpoint) so the stats sync (`/api/auth/me`) does not fail.

---

## 3. Important SDK Workarounds

### Clerk SDK Constructor Bug

The Clerk SDK ignores `httpService` when calling `super(...)` in `ClerkAuthConfig`. We work around this by defining `AppClerkAuthConfig` in [app.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/lib/app/app.dart):

```dart
class AppClerkAuthConfig extends ClerkAuthConfig {
  @override
  final clerk.HttpService? httpService;

  AppClerkAuthConfig({
    required super.publishableKey,
    this.httpService,
    super.loading,
  });
}
```

**Always** use `AppClerkAuthConfig` when configuring `ClerkAuth` in production or testing environments.

---

## 4. Testing Guidelines

### Active Tickers & Progress Indicators

- **Do NOT use `tester.pumpAndSettle()`** immediately after rendering widgets with active tickers (such as `CircularProgressIndicator` or indeterminate animations). This causes widget tests to time out.
- **Instead, use timed pumps**:
  ```dart
  await tester.pump(const Duration(milliseconds: 200));
  ```

### Mocking Platform Channels (e.g. `path_provider`)

Clerk initialization accesses local directories for storage caching. In unit/widget tests, mock the platform channels to avoid crashes:

```dart
TestWidgetsFlutterBinding.ensureInitialized();
const MethodChannel('plugins.flutter.io/path_provider')
    .setMockMethodCallHandler((MethodCall methodCall) async {
  return '.'; // Return a valid local path directory stub
});
```

### Mock Clerk HTTP Service

Always wrap widgets under test in `ClerkAuth` with `MockHttpService` to prevent real network requests. Refer to [mock_http_service.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/test/mocks/mock_http_service.dart) for prepopulated responses (such as `janeDoeClientResponse`).

---

## 5. Standard Build Commands

- **Run Tests**:
  ```powershell
  flutter test
  ```
- **Build APK (Android)**:
  ```powershell
  flutter build apk --debug
  ```
