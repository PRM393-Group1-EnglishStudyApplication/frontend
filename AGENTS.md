# Developer Agent Guide: Frontend Configuration & Architecture

Welcome! This guide explains the architecture, setup instructions, and testing requirements for this Flutter codebase.

## 1. Authentication & Token Sync Architecture

The application uses **Clerk** for user authentication and session management on the client side, coupled with a **MongoDB backend** that acts as the source of truth for user stats (XP, level, streak, etc.).

### Token Sync Mechanism
The Clerk Flutter SDK creates auth states asynchronously, which can cause standard listeners to miss the session token resolution or race during boot. To ensure the backend doesn't reject requests with a `401 Unauthorized` (`"Ban can dang nhap de truy cap."`), we use a dual-path token sync pattern in [auth_gate.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/lib/features/auth/presentation/widgets/auth_gate.dart):
1. **Synchronous Fallback**: Immediately attempts to retrieve the token via `session?.lastActiveToken?.jwt` upon sign-in inside Clerk's `signedInBuilder` to minimize delays.
2. **Stream Subscription**: Listens to `sessionTokenStream` to capture the token dynamically as soon as Clerk emits or refreshes it in the background.
3. **Riverpod Provider**: The retrieved token is saved to `clerkTokenProvider` (defined in [auth_providers.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/lib/features/auth/presentation/providers/auth_providers.dart)), which is read by `Dio` to inject the `Authorization: Bearer <token>` header.

### Non-Blocking Sync Flow
- Transition from onboarding / sign-in screen to `HomePage` is **instant** upon Clerk login success.
- Cached Clerk profile data (Name, Email, Image URL) from `ClerkAuth.userOf(context)` is displayed immediately.
- User stats (XP, level, streak) are fetched asynchronously in the background via `currentUserProvider` calling the backend (`GET /api/auth/me`).
- Scoped `Consumer` widgets wrap stats panels to display inline spinners or errors, ensuring the main layout remains fully interactive.

---

## 2. Onboarding & Client-Side Stats Overlay

To allow new users to experience the application before registering, we use a localized state machine on the frontend with **zero backend modifications**.

### The Onboarding State Flow
Unauthenticated users progress through a linear onboarding wizard:
```
[State: PURPOSE] -> [State: LEVEL] -> [State: QUIZ (3 Questions)] -> [State: CELEBRATION] -> [State: REGISTRATION WALL]
```
- **Wizard Implementation**: Handled in [onboarding_wizard.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/lib/features/onboarding/presentation/screens/onboarding_wizard.dart).
- **Quiz Questions**: Stored locally in [onboarding_questions.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/lib/features/onboarding/constants/onboarding_questions.dart) split by difficulty levels.

### Persistent Stats Overlay
1. **Temporary Storage**: During the quiz/celebration, choices and scores are cached locally in `SharedPreferences`.
2. **Post-Registration Overlay**: Once the user signs up/in, `CurrentUserNotifier.loadUser()` (in [auth_providers.dart](file:///d:/Study/2026_Summer/PRM393/group-prj/frontend/lib/features/auth/presentation/providers/auth_providers.dart)) fetches the user stats from `/api/auth/me`.
3. It associates the local onboarding data with the new `userId` (using keys like `onboarding_purpose_{userId}`), then overrides/overlays the retrieved backend stats in-memory:
   - **XP Boost**: Adds `+150 XP` onboarding bonus.
   - **Level Sync**: Computes the user's level.
4. **Resilience Workaround**: To prevent the app from crashing due to `MissingPluginException` (e.g., if `SharedPreferences` platform channel isn't initialized/recompiled yet during hot restarts), all storage calls are wrapped in `try-catch` blocks, falling back gracefully to in-memory state.

---

## 3. Environment Variables & Configurations

### Clerk Publishable Key
- **Format Constraint**: The Clerk SDK parses and base64-decodes the domain suffix of the publishable key. Passing arbitrary placeholders (like `'pk_test_placeholder'`) will throw a `FormatException` during initialization, causing the app to hang.
- **Valid Test Key format**: `pk_test_Y2xlcmsucHJtLmxlYXJuaW5nJA==` (decodes to `clerk.prm.learning$`).

### HTTP Service Configuration (`Dio`)
- **Connection & Receive Timeouts**: Set to `60 seconds` to accommodate Render free tier backend cold starts (which can take 30-50 seconds).
- **Network Logging**: Detailed HTTP logs are printed with the `DIO_LOG:` prefix for easy grep filtering.

---

## 4. Important SDK Workarounds

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

## 5. Testing Guidelines

### Active Tickers & Progress Indicators
- **Do NOT use `tester.pumpAndSettle()`** immediately after rendering widgets with active tickers (such as `CircularProgressIndicator` or indeterminate animations). This causes widget tests to time out.
- **Instead, use timed pumps**:
  ```dart
  await tester.pump(const Duration(milliseconds: 200));
  ```

### Mocking Platform Channels (e.g., `path_provider`)
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

## 6. Standard Build & Test Commands

- **Run All Tests**:
  ```powershell
  flutter test
  ```
- **Run Specific Tests**:
  ```powershell
  flutter test test/features/onboarding/onboarding_wizard_test.dart
  ```
- **Build APK (Android)**:
  ```powershell
  flutter build apk --debug
  ```
