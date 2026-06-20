import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  group('ExpirationDateField', () {
    testWidgets('inserts / after the second digit', (tester) async {
      final controller = PciFieldState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExpirationDateField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), '1230');
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '12/30');
    });

    testWidgets('rejects month > 12', (tester) async {
      final controller = PciFieldState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExpirationDateField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), '13');
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text.isEmpty, isTrue);
    });
  });
}
