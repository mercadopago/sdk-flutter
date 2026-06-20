import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  group('CardNumberField', () {
    testWidgets('auto-formats with a space every 4 digits', (tester) async {
      final controller = PciFieldState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardNumberField(controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '4111111111111111');
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '4111 1111 1111 1111');
      expect(controller.rawValue, '4111111111111111');
    });

    testWidgets('onBinChanged fires at 8th digit', (tester) async {
      final controller = PciFieldState();
      final bins = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardNumberField(
              controller: controller,
              onBinChanged: bins.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '41111111');
      await tester.pump();

      expect(bins, ['41111111']);
    });
  });
}
