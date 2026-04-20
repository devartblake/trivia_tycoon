import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/store/store_payment_return_screen.dart';

void main() {
  Widget buildHarness(
      StoreReturnMode mode, Map<String, String> queryParameters) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => StorePaymentReturnScreen(
            mode: mode,
            queryParameters: queryParameters,
          ),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders purchase cancel state without backend polling',
      (tester) async {
    await tester.pumpWidget(
      buildHarness(
        StoreReturnMode.purchase,
        {
          'provider': 'stripe',
          'status': 'cancel',
          'sku': 'powerup:skip',
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Checkout canceled'), findsOneWidget);
    expect(
      find.textContaining('No charge was completed'),
      findsOneWidget,
    );
    expect(find.text('Back to Store'), findsOneWidget);
  });

  testWidgets('renders subscription cancel state without backend polling',
      (tester) async {
    await tester.pumpWidget(
      buildHarness(
        StoreReturnMode.subscription,
        {
          'provider': 'paypal',
          'status': 'cancel',
          'tier': 'premium',
          'billingPeriod': 'monthly',
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Checkout canceled'), findsOneWidget);
    expect(
      find.textContaining('No subscription changes were applied'),
      findsOneWidget,
    );
    expect(find.text('Back to Offers'), findsOneWidget);
  });
}
