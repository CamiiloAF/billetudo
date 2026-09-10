import 'package:billetudo/core/widgets/scroll_aware_fab.dart';
import 'package:billetudo/core/widgets/scroll_aware_fab_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// GH-26: covers the shared scroll-direction logic (`HomePage` and
/// `TransactionsPage` both mix this in) against a minimal scrollable host
/// instead of duplicating the assertion per screen.
void main() {
  testWidgets('scrolling down hides the FAB, scrolling up brings it back',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ScrollHarness()));

    expect(find.text('visible'), findsOneWidget);

    // Drag up moves content up, i.e. the user scrolls down the list.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    expect(find.text('hidden'), findsOneWidget);

    // Drag back down: scrolling up brings the FAB back.
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();

    expect(find.text('visible'), findsOneWidget);
  });
}

class _ScrollHarness extends StatefulWidget {
  const _ScrollHarness();

  @override
  State<_ScrollHarness> createState() => _ScrollHarnessState();
}

class _ScrollHarnessState extends State<_ScrollHarness>
    with ScrollAwareFabVisibility<_ScrollHarness> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ScrollAwareFab(
        visible: fabVisible,
        child: Text(fabVisible ? 'visible' : 'hidden'),
      ),
      body: ListView.builder(
        controller: fabScrollController,
        itemCount: 50,
        itemBuilder: (context, index) => SizedBox(
          height: 60,
          child: Text('item $index'),
        ),
      ),
    );
  }
}
