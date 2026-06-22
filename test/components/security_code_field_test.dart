import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  group('SecurityCodeField', () {
    testWidgets('shows obscured input', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('onFilled fires when expectedLength digits entered', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      final filled = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityCodeField(
              controller: controller,
              expectedLength: 3,
              onFilled: filled.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(filled, ['123']);
    });

    testWidgets('controller rawValue reflects typed digits', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '456');
      await tester.pump();
      expect(controller.rawValue, '456');
    });

    testWidgets('onFilled does not fire below expectedLength', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      final filled = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityCodeField(
              controller: controller,
              expectedLength: 4,
              onFilled: filled.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(filled, isEmpty);
    });

    testWidgets('respects enabled = false', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityCodeField(controller: controller, enabled: false),
          ),
        ),
      );
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });
  });
}
