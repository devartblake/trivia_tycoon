import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/ui_components/synaptix_toast/synaptix_toast_service.dart';

void main() {
  testWidgets('SynaptixToastService renders a toast through global app keys',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: SynaptixToastService.navigatorKey,
        scaffoldMessengerKey: SynaptixToastService.scaffoldMessengerKey,
        home: const Scaffold(
          body: Center(child: Text('Home')),
        ),
      ),
    );

    unawaited(
      SynaptixToastService.compact(
        message: 'Saved everywhere',
        duration: const Duration(milliseconds: 10),
      ),
    );

    await tester.pump();

    expect(find.text('Saved everywhere'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
