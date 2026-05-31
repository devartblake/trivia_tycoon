import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/providers/user_type_filter_provider.dart';

void main() {
  // -------------------------------------------------------------------------
  // UserType enum
  // -------------------------------------------------------------------------

  group('UserType enum', () {
    test('has exactly 3 values', () {
      expect(UserType.values, hasLength(3));
    });

    test('contains UserType.all', () {
      expect(UserType.values, contains(UserType.all));
    });

    test('contains UserType.free', () {
      expect(UserType.values, contains(UserType.free));
    });

    test('contains UserType.premium', () {
      expect(UserType.values, contains(UserType.premium));
    });

    test('all values are distinct', () {
      expect(UserType.values.toSet().length, UserType.values.length);
    });
  });

  // -------------------------------------------------------------------------
  // userTypeFilterProvider — initial state
  // -------------------------------------------------------------------------

  group('userTypeFilterProvider — initial state', () {
    test('initial value is UserType.all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(userTypeFilterProvider), UserType.all);
    });

    test('two separate containers both start at UserType.all', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);

      expect(c1.read(userTypeFilterProvider), UserType.all);
      expect(c2.read(userTypeFilterProvider), UserType.all);
    });
  });

  // -------------------------------------------------------------------------
  // userTypeFilterProvider — state updates
  // -------------------------------------------------------------------------

  group('userTypeFilterProvider — state updates', () {
    test('can be updated to UserType.premium', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(userTypeFilterProvider.notifier)
          .update((_) => UserType.premium);

      expect(container.read(userTypeFilterProvider), UserType.premium);
    });

    test('can be updated to UserType.free', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(userTypeFilterProvider.notifier)
          .update((_) => UserType.free);

      expect(container.read(userTypeFilterProvider), UserType.free);
    });

    test('can cycle through all values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final type in UserType.values) {
        container
            .read(userTypeFilterProvider.notifier)
            .update((_) => type);
        expect(container.read(userTypeFilterProvider), type);
      }
    });

    test('updating one container does not affect another', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);

      c1.read(userTypeFilterProvider.notifier).update((_) => UserType.premium);

      expect(c1.read(userTypeFilterProvider), UserType.premium);
      expect(c2.read(userTypeFilterProvider), UserType.all);
    });
  });
}
