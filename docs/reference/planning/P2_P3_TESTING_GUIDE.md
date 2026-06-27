# Unit Testing Guide - Trivia Tycoon Auth System

## Setup

### 1. Add Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  test: ^1.24.0
```

```bash
flutter pub get
```

### 2. Create Test Directory Structure

```bash
mkdir -p test/core/services
mkdir -p test/core/manager
mkdir -p test/game/providers
```

---

## Test Files

### 1. AuthTokenStore Tests

**File:** `test/core/services/auth_token_store_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';

@GenerateMocks([Box])
import 'auth_token_store_test.mocks.dart';

void main() {
  late MockBox mockBox;
  late AuthTokenStore authTokenStore;

  setUp(() {
    mockBox = MockBox();
    authTokenStore = AuthTokenStore(mockBox);
  });

  group('AuthSession', () {
    test('hasTokens returns true when both tokens exist', () {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
      );

      expect(session.hasTokens, true);
    });

    test('hasTokens returns false when access token is empty', () {
      final session = AuthSession(
        accessToken: '',
        refreshToken: 'refresh456',
      );

      expect(session.hasTokens, false);
    });

    test('isExpired returns false when no expiry set', () {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
      );

      expect(session.isExpired, false);
    });

    test('isExpired returns true when token is expired', () {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        expiresAtUtc: DateTime.now().toUtc().subtract(Duration(hours: 1)),
      );

      expect(session.isExpired, true);
    });

    test('role getter returns correct role from metadata', () {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        metadata: {'role': 'admin'},
      );

      expect(session.role, 'admin');
    });

    test('isPremium returns true when metadata contains isPremium', () {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        metadata: {'isPremium': true},
      );

      expect(session.isPremium, true);
    });

    test('toJson and fromJson work correctly', () {
      final original = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        userId: 'user789',
        metadata: {'role': 'admin', 'isPremium': true},
      );

      final json = original.toJson();
      final restored = AuthSession.fromJson(json);

      expect(restored.accessToken, original.accessToken);
      expect(restored.refreshToken, original.refreshToken);
      expect(restored.userId, original.userId);
      expect(restored.metadata, original.metadata);
    });
  });

  group('AuthTokenStore', () {
    test('save stores all session data', () async {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        userId: 'user789',
        expiresAtUtc: DateTime.parse('2026-12-31T23:59:59Z'),
        metadata: {'role': 'player'},
      );

      await authTokenStore.save(session);

      verify(mockBox.put('auth_access_token', 'access123')).called(1);
      verify(mockBox.put('auth_refresh_token', 'refresh456')).called(1);
      verify(mockBox.put('auth_user_id', 'user789')).called(1);
      verify(mockBox.put('auth_expires_at_utc', any)).called(1);
      verify(mockBox.put('auth_metadata', any)).called(1);
    });

    test('load returns session from storage', () {
      when(mockBox.get('auth_access_token', defaultValue: ''))
          .thenReturn('access123');
      when(mockBox.get('auth_refresh_token', defaultValue: ''))
          .thenReturn('refresh456');
      when(mockBox.get('auth_user_id')).thenReturn('user789');
      when(mockBox.get('auth_expires_at_utc')).thenReturn(null);
      when(mockBox.get('auth_metadata')).thenReturn('{"role":"player"}');

      final session = authTokenStore.load();

      expect(session.accessToken, 'access123');
      expect(session.refreshToken, 'refresh456');
      expect(session.userId, 'user789');
      expect(session.metadata?['role'], 'player');
    });

    test('clear removes all tokens', () async {
      await authTokenStore.clear();

      verify(mockBox.delete('auth_access_token')).called(1);
      verify(mockBox.delete('auth_refresh_token')).called(1);
      verify(mockBox.delete('auth_expires_at_utc')).called(1);
      verify(mockBox.delete('auth_user_id')).called(1);
      verify(mockBox.delete('auth_metadata')).called(1);
    });

    test('hasTokens returns true when tokens exist', () {
      when(mockBox.get('auth_access_token', defaultValue: ''))
          .thenReturn('access123');
      when(mockBox.get('auth_refresh_token', defaultValue: ''))
          .thenReturn('refresh456');

      expect(authTokenStore.hasTokens(), true);
    });

    test('getRole returns role from metadata', () {
      when(mockBox.get('auth_metadata')).thenReturn('{"role":"admin"}');

      expect(authTokenStore.getRole(), 'admin');
    });

    test('isPremium returns premium status from metadata', () {
      when(mockBox.get('auth_metadata')).thenReturn('{"isPremium":true}');

      expect(authTokenStore.isPremium(), true);
    });
  });
}
```

---

### 2. AuthService Tests

**File:** `test/core/services/auth_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:trivia_tycoon/core/services/auth_service.dart';
import 'package:trivia_tycoon/core/services/auth_api_client.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';

@GenerateMocks([AuthApiClient, AuthTokenStore, DeviceIdService])
import 'auth_service_test.mocks.dart';

void main() {
  late MockAuthApiClient mockApiClient;
  late MockAuthTokenStore mockTokenStore;
  late MockDeviceIdService mockDeviceIdService;
  late AuthService authService;

  setUp(() {
    mockApiClient = MockAuthApiClient();
    mockTokenStore = MockAuthTokenStore();
    mockDeviceIdService = MockDeviceIdService();
    
    authService = AuthService(
      deviceId: mockDeviceIdService,
      tokenStore: mockTokenStore,
      api: mockApiClient,
    );
  });

  group('login', () {
    test('successful login saves session', () async {
      final mockSession = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        userId: 'user789',
      );

      when(mockApiClient.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockSession);

      when(mockTokenStore.save(any)).thenAnswer((_) async {});

      await authService.login(email: 'test@test.com', password: 'password123');

      verify(mockApiClient.login(
        email: 'test@test.com',
        password: 'password123',
      )).called(1);
      
      verify(mockTokenStore.save(mockSession)).called(1);
    });

    test('failed login throws exception', () async {
      when(mockApiClient.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Invalid credentials'));

      expect(
        () => authService.login(email: 'test@test.com', password: 'wrong'),
        throwsException,
      );
    });
  });

  group('signup', () {
    test('successful signup saves session', () async {
      final mockSession = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        userId: 'user789',
      );

      when(mockApiClient.signup(
        email: anyNamed('email'),
        password: anyNamed('password'),
        username: anyNamed('username'),
      )).thenAnswer((_) async => mockSession);

      when(mockTokenStore.save(any)).thenAnswer((_) async {});

      await authService.signup(
        email: 'test@test.com',
        password: 'password123',
        username: 'TestUser',
      );

      verify(mockTokenStore.save(mockSession)).called(1);
    });
  });

  group('refresh', () {
    test('successful refresh updates token store', () async {
      final existingSession = AuthSession(
        accessToken: 'old_access',
        refreshToken: 'refresh456',
      );

      final newSession = AuthSession(
        accessToken: 'new_access',
        refreshToken: 'refresh456',
      );

      when(mockDeviceIdService.getOrCreate())
          .thenAnswer((_) async => 'device123');
      
      when(mockTokenStore.load()).thenReturn(existingSession);
      
      when(mockApiClient.refresh(
        refreshToken: anyNamed('refreshToken'),
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => newSession);

      when(mockTokenStore.save(any)).thenAnswer((_) async {});

      await authService.refresh();

      verify(mockTokenStore.save(newSession)).called(1);
    });
  });

  group('logout', () {
    test('logout clears token store', () async {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
        userId: 'user789',
      );

      when(mockDeviceIdService.getOrCreate())
          .thenAnswer((_) async => 'device123');
      
      when(mockTokenStore.load()).thenReturn(session);
      
      when(mockApiClient.logout(
        deviceId: anyNamed('deviceId'),
        userId: anyNamed('userId'),
        accessToken: anyNamed('accessToken'),
      )).thenAnswer((_) async {});

      when(mockTokenStore.clear()).thenAnswer((_) async {});

      await authService.logout();

      verify(mockTokenStore.clear()).called(1);
    });

    test('logout clears store even if API call fails', () async {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
      );

      when(mockDeviceIdService.getOrCreate())
          .thenAnswer((_) async => 'device123');
      
      when(mockTokenStore.load()).thenReturn(session);
      
      when(mockApiClient.logout(
        deviceId: anyNamed('deviceId'),
        userId: anyNamed('userId'),
        accessToken: anyNamed('accessToken'),
      )).thenThrow(Exception('Network error'));

      when(mockTokenStore.clear()).thenAnswer((_) async {});

      await authService.logout();

      verify(mockTokenStore.clear()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('returns true when has valid tokens', () {
      final session = AuthSession(
        accessToken: 'access123',
        refreshToken: 'refresh456',
      );

      when(mockTokenStore.load()).thenReturn(session);

      expect(authService.isLoggedIn, true);
    });

    test('returns false when no tokens', () {
      final session = AuthSession(
        accessToken: '',
        refreshToken: '',
      );

      when(mockTokenStore.load()).thenReturn(session);

      expect(authService.isLoggedIn, false);
    });
  });
}
```

---

### 3. Generate Mocks

Run this command to generate mock classes:

```bash
flutter pub run build_runner build
```

This will create `*.mocks.dart` files next to your test files.

---

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/core/services/auth_service_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Test Best Practices

### 1. **AAA Pattern**
- **Arrange:** Set up test data and mocks
- **Act:** Execute the code being tested
- **Assert:** Verify the results

### 2. **One Assertion Per Test**
Each test should verify one thing. Split complex tests into multiple smaller tests.

### 3. **Descriptive Names**
```dart
// ❌ Bad
test('test1', () {...});

// ✅ Good
test('login saves session when credentials are valid', () {...});
```

### 4. **Test Edge Cases**
- Empty strings
- Null values
- Network errors
- Expired tokens
- Malformed data

### 5. **Mock External Dependencies**
Never make real network calls in unit tests. Always mock:
- HTTP clients
- Databases
- File system
- External APIs

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - run: flutter pub get
      
      - run: flutter test
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

---

## Testing Checklist

- [ ] AuthTokenStore tests passing
- [ ] AuthService tests passing
- [ ] LoginManager tests written
- [ ] AuthProviders tests written
- [ ] Coverage > 70%
- [ ] All edge cases covered
- [ ] CI/CD pipeline configured

---

## Next Steps

1. **Run existing tests:** `flutter test`
2. **Add integration tests:** Test full auth flows
3. **Add widget tests:** Test UI components
4. **Monitor coverage:** Aim for 70%+ coverage
5. **Automate in CI:** Run tests on every commit

Good testing = confident deployments! 🧪✅
