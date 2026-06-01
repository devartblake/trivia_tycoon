import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/helpers/responsive_layout.dart';

void main() {
  test('AppBreakpoints classifies mobile, tablet, and desktop widths', () {
    expect(AppBreakpoints.classify(390), AppLayoutClass.mobile);
    expect(AppBreakpoints.classify(900), AppLayoutClass.tablet);
    expect(AppBreakpoints.classify(1280), AppLayoutClass.desktop);
    expect(AppBreakpoints.classify(1440), AppLayoutClass.desktop);
  });

  testWidgets('AppAdaptiveScaffold shows rail and right panel on wide layouts',
      (tester) async {
    await _pumpAdaptiveScaffold(tester, const Size(1280, 900));

    expect(find.text('rail'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    expect(find.text('right'), findsOneWidget);
    expect(find.text('drawer'), findsNothing);
  });

  testWidgets('AppAdaptiveScaffold uses drawer below rail breakpoint',
      (tester) async {
    await _pumpAdaptiveScaffold(tester, const Size(390, 900));

    expect(find.text('rail'), findsNothing);
    expect(find.text('right'), findsNothing);
    expect(find.text('body'), findsOneWidget);

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('drawer'), findsOneWidget);
  });
}

Future<void> _pumpAdaptiveScaffold(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(
      home: AppAdaptiveScaffold(
        topBar: SizedBox(height: 48, child: Text('top')),
        drawer: Drawer(child: Text('drawer')),
        rail: Text('rail'),
        rightPanel: Text('right'),
        body: Text('body'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
