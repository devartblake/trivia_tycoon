import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trivia_tycoon/ui_components/qr_code/widgets/qr_code_widget.dart';

void main() {
  testWidgets('QrCodeWidget renders a standards-compliant QR image',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QrCodeWidget(
            data: 'https://app.synaptixplay.com/link?token=abc123',
          ),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('Error'), findsNothing);
  });

  testWidgets('QrCodeWidget shows an error state for empty data',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QrCodeWidget(data: ''),
        ),
      ),
    );

    expect(find.text('No data provided'), findsOneWidget);
  });
}
