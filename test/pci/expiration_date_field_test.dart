import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  group('ExpirationDateField', () {
    testWidgets('inserts / after the second digit', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
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
      addTearDown(controller.dispose);
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

    testWidgets('removing the widget clears retained expiration data', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExpirationDateField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '1230');

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
          home: Scaffold(body: ExpirationDateField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '1230');

      controller.clear();
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('replacing the controller clears both expiration contexts', (
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
                return ExpirationDateField(controller: controller);
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '1230');

      rebuild(() => controller = second);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(first.length, 0);
      expect(second.length, 0);
    });

    testWidgets('backgrounding clears visible and retained expiration data', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExpirationDateField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '1230');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(controller.length, 0);
    });

    testWidgets(
      'losing foreground focus clears visible and retained expiration data',
      (tester) async {
        final controller = PciFieldState();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ExpirationDateField(controller: controller)),
          ),
        );
        await tester.enterText(find.byType(TextField), '1230');

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, isEmpty);
        expect(controller.length, 0);
      },
    );
  });
}
