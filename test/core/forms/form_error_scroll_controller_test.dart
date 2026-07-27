import 'package:billetudo/core/forms/form_error_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormErrorScrollController', () {
    test('keyFor returns the same key for a field across calls', () {
      final controller = FormErrorScrollController();
      final first = controller.keyFor('name');
      final second = controller.keyFor('name');
      final other = controller.keyFor('amount');

      expect(identical(first, second), isTrue);
      expect(identical(first, other), isFalse);
    });

    testWidgets('scrollToField brings a far-down field into view',
        (tester) async {
      final controller = FormErrorScrollController();
      final scroll = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scroll,
              // Build every row so the test exercises the controller's scroll
              // logic, not the ListView's off-screen laziness.
              cacheExtent: 10000,
              children: [
                for (var i = 0; i < 20; i++)
                  const SizedBox(height: 200, child: Text('filler')),
                KeyedSubtree(
                  key: controller.keyFor('target'),
                  child: const SizedBox(height: 200, child: Text('target')),
                ),
              ],
            ),
          ),
        ),
      );

      // The target sits far below the fold, so nothing is scrolled yet.
      expect(scroll.offset, 0);

      controller.scrollToField('target');
      await tester.pumpAndSettle();

      expect(scroll.offset, greaterThan(0));
    });

    testWidgets('scrollToField is a no-op for an unregistered field',
        (tester) async {
      final controller = FormErrorScrollController();
      final scroll = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scroll,
              children: [
                for (var i = 0; i < 20; i++)
                  const SizedBox(height: 200, child: Text('filler')),
              ],
            ),
          ),
        ),
      );

      controller.scrollToField('missing');
      controller.scrollToField(null);
      await tester.pumpAndSettle();

      expect(scroll.offset, 0);
    });
  });
}
