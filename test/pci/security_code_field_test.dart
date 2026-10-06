import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago/mercadopago.dart';

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

    testWidgets('onFilled fires when expectedLength digits entered', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      var filled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityCodeField(
              controller: controller,
              expectedLength: 3,
              onFilled: () => filled = true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(filled, isTrue);
    });

    testWidgets('controller retains typed digits for internal tokenization', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '456');
      await tester.pump();
      expect(controller.length, 3);
    });

    testWidgets('removing the widget clears retained CVV data', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '456');

      await tester.pumpWidget(const SizedBox.shrink());

      expect(controller.length, 0);
    });

    testWidgets('clearing the PCI controller also clears the visible field', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '456');

      controller.clear();
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('replacing the controller clears both CVV contexts', (
      tester,
    ) async {
      final first = PciFieldState();
      final second = PciFieldState();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var controller = first;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SecurityCodeField(controller: controller);
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '123');

      rebuild(() => controller = second);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(first.length, 0);
      expect(second.length, 0);
    });

    testWidgets('backgrounding clears visible and retained CVV data', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '456');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(controller.length, 0);
    });

    testWidgets(
      'losing foreground focus clears visible and retained CVV data',
      (tester) async {
        final controller = PciFieldState();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SecurityCodeField(controller: controller)),
          ),
        );
        await tester.enterText(find.byType(TextField), '456');

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, isEmpty);
        expect(controller.length, 0);
      },
    );

    testWidgets('onFilled does not fire below expectedLength', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      var filled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityCodeField(
              controller: controller,
              expectedLength: 4,
              onFilled: () => filled = true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(filled, isFalse);
    });

    testWidgets('accepts four digits while the card brand is unknown', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SecurityCodeField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      expect(controller.length, 4);
    });

    testWidgets('does not signal completion while the brand is unknown', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      var filled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityCodeField(
              controller: controller,
              onFilled: () => filled = true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      expect(filled, isFalse);
    });

    testWidgets('initial metadata resolution preserves in-progress CVV', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      int? expectedLength;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SecurityCodeField(
                  controller: controller,
                  expectedLength: expectedLength,
                );
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '123');

      rebuild(() => expectedLength = 4);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '123');
      expect(controller.length, 3);
    });

    testWidgets('changing expectedLength clears visible and retained CVV', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      var expectedLength = 3;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SecurityCodeField(
                  controller: controller,
                  expectedLength: expectedLength,
                );
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '123');

      rebuild(() => expectedLength = 4);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(controller.length, 0);
      expect(textField.maxLength, 4);
    });

    testWidgets('rejects unsupported expectedLength values', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);

      expect(
        () => SecurityCodeField(controller: controller, expectedLength: 5),
        throwsAssertionError,
      );
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
