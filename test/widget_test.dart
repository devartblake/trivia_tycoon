// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/bootstrap/synaptix_app.dart';

void main() {
  testWidgets('SynaptixApp renders', (WidgetTester tester) async {
    // SynaptixApp is a ConsumerStatefulWidget that reads providers in
    // didChangeDependencies, so it must be hosted inside a ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(
        child: SynaptixApp(),
      ),
    );
    expect(find.byType(SynaptixApp), findsOneWidget);
  });
}
