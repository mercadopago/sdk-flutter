import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadopago_sdk_flutter/mercadopago_sdk_flutter.dart';

void main() {
  group('CardNumberField', () {
    testWidgets('auto-formats with a space every 4 digits', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CardNumberField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), '4111111111111111');
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '4111 1111 1111 1111');
      expect(controller.length, 16);
    });

    testWidgets('onBinChanged fires at the 8th digit', (tester) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      final bins = <String?>[];
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

    testWidgets('onBinChanged emits null when BIN becomes incomplete', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      final bins = <String?>[];
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
      await tester.enterText(find.byType(TextField), '41111');
      await tester.pump();

      expect(bins, ['41111111', null]);
    });

    testWidgets('removing the widget clears retained card data', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CardNumberField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '4111111111111111');

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
          home: Scaffold(body: CardNumberField(controller: controller)),
        ),
      );
      await tester.enterText(find.byType(TextField), '4111111111111111');

      controller.clear();
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('replacing the controller clears both card contexts', (
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
                return CardNumberField(controller: controller);
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '4111111111111111');

      rebuild(() => controller = second);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(first.length, 0);
      expect(second.length, 0);
    });

    testWidgets('backgrounding the app clears visible and retained card data', (
      tester,
    ) async {
      final controller = PciFieldState();
      addTearDown(controller.dispose);
      final bins = <String?>[];
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
      await tester.enterText(find.byType(TextField), '4111111111111111');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      expect(controller.length, 0);
      expect(bins, ['41111111', null]);
    });

    testWidgets(
      'losing foreground focus clears visible and retained card data',
      (tester) async {
        final controller = PciFieldState();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CardNumberField(controller: controller)),
          ),
        );
        await tester.enterText(find.byType(TextField), '4111111111111111');

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
