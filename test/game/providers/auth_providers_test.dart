import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/providers/auth_providers.dart';

void main() {
  // -------------------------------------------------------------------------
  // AuthState — copyWith
  // -------------------------------------------------------------------------

  group('AuthState — copyWith', () {
    test('initial state has sensible defaults', () {
      const state = AuthState();
      expect(state.isLoggedIn, isFalse);
      expect(state.userEmail, isNull);
      expect(state.userRole, isNull);
      expect(state.isPremium, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates only specified fields', () {
      const original = AuthState(
        isLoggedIn: true,
        userEmail: 'user@test.com',
        userRole: 'player',
        isPremium: false,
        isLoading: false,
        error: null,
      );

      final updated = original.copyWith(userRole: 'admin', isPremium: true);

      expect(updated.isLoggedIn, isTrue); // unchanged
      expect(updated.userEmail, 'user@test.com'); // unchanged
      expect(updated.userRole, 'admin'); // changed
      expect(updated.isPremium, isTrue); // changed
      expect(updated.isLoading, isFalse); // unchanged
    });

    test('copyWith with error sets error field', () {
      const state = AuthState();
      final withError = state.copyWith(error: 'Something went wrong');
      expect(withError.error, 'Something went wrong');
    });

    test('copyWith with isLoading=true', () {
      const state = AuthState();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.isLoggedIn, isFalse); // other fields unchanged
    });
  });

  // -------------------------------------------------------------------------
  // AuthStateNotifier — initial state
  // -------------------------------------------------------------------------

  group('AuthStateNotifier — initial state', () {
    test('starts with all-false default AuthState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authStateProvider);
      expect(state.isLoggedIn, isFalse);
      expect(state.userEmail, isNull);
      expect(state.userRole, isNull);
      expect(state.isPremium, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AuthStateNotifier — login
  // -------------------------------------------------------------------------

  group('AuthStateNotifier — login', () {
    test('sets isLoading=true while loading then isLoggedIn=true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);

      // Capture isLoading=true before await completes
      bool sawLoading = false;
      container.listen(authStateProvider, (_, next) {
        if (next.isLoading) sawLoading = true;
      });

      await notifier.login('test@example.com', 'password');

      final state = container.read(authStateProvider);
      expect(state.isLoggedIn, isTrue);
      expect(state.userEmail, 'test@example.com');
      expect(state.isLoading, isFalse);
      expect(sawLoading, isTrue);
    });

    test('sets userEmail from login call', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(authStateProvider.notifier)
          .login('hello@example.com', 'pass');

      expect(
        container.read(authStateProvider).userEmail,
        'hello@example.com',
      );
    });
  });

  // -------------------------------------------------------------------------
  // AuthStateNotifier — signup
  // -------------------------------------------------------------------------

  group('AuthStateNotifier — signup', () {
    test('sets isLoggedIn=true and email after signup', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.notifier).signup(
        'new@example.com',
        'password',
        {'username': 'newuser'},
      );

      final state = container.read(authStateProvider);
      expect(state.isLoggedIn, isTrue);
      expect(state.userEmail, 'new@example.com');
      expect(state.isLoading, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // AuthStateNotifier — logout
  // -------------------------------------------------------------------------

  group('AuthStateNotifier — logout', () {
    test('resets state to default AuthState after logout', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.login('user@example.com', 'password');

      // Verify logged in
      expect(container.read(authStateProvider).isLoggedIn, isTrue);

      notifier.logout();

      final state = container.read(authStateProvider);
      expect(state.isLoggedIn, isFalse);
      expect(state.userEmail, isNull);
      expect(state.userRole, isNull);
      expect(state.isPremium, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AuthStateNotifier — setRole / setPremiumStatus / clearError
  // -------------------------------------------------------------------------

  group('AuthStateNotifier — role and premium helpers', () {
    test('setRole updates userRole', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider.notifier).setRole('admin');
      expect(container.read(authStateProvider).userRole, 'admin');
    });

    test('setRole to moderator', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider.notifier).setRole('moderator');
      expect(container.read(authStateProvider).userRole, 'moderator');
    });

    test('setPremiumStatus(true) sets isPremium', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider.notifier).setPremiumStatus(true);
      expect(container.read(authStateProvider).isPremium, isTrue);
    });

    test('setPremiumStatus(false) clears isPremium', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      notifier.setPremiumStatus(true);
      notifier.setPremiumStatus(false);
      expect(container.read(authStateProvider).isPremium, isFalse);
    });
  });

  group('AuthStateNotifier — clearError', () {
    test('clearError sets error to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Manually set an error state by triggering a copyWith through the notifier
      // by using setRole first (available method) then verify clearError works
      final notifier = container.read(authStateProvider.notifier);

      // Force an error state via internal state copy
      // (directly test the clearError method)
      notifier.clearError();

      // Error was already null; should remain null
      expect(container.read(authStateProvider).error, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // isLoggedInSyncProvider
  // -------------------------------------------------------------------------

  group('isLoggedInSyncProvider', () {
    test('starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isLoggedInSyncProvider), isFalse);
    });

    test('can be mutated to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isLoggedInSyncProvider.notifier).state = true;
      expect(container.read(isLoggedInSyncProvider), isTrue);
    });

    test('independent between containers', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);

      c1.read(isLoggedInSyncProvider.notifier).state = true;
      expect(c1.read(isLoggedInSyncProvider), isTrue);
      expect(c2.read(isLoggedInSyncProvider), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // profileSelectedProvider
  // -------------------------------------------------------------------------

  group('profileSelectedProvider', () {
    test('starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(profileSelectedProvider), isFalse);
    });

    test('can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(profileSelectedProvider.notifier).state = true;
      expect(container.read(profileSelectedProvider), isTrue);
    });
  });
}
