import 'package:billetudo/core/widgets/scroll_aware_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// GH-26: the wrapper itself only drives the slide/fade animation; the
/// scroll-direction logic lives in `ScrollAwareFabVisibility` and is covered
/// separately.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('visible: true renders the child fully opaque, no offset',
      (tester) async {
    await tester.pumpWidget(
      appWith(const ScrollAwareFab(visible: true, child: Text('fab'))),
    );

    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(slide.offset, Offset.zero);
    expect(opacity.opacity, 1);
  });

  testWidgets('visible: false slides down and fades out', (tester) async {
    await tester.pumpWidget(
      appWith(const ScrollAwareFab(visible: false, child: Text('fab'))),
    );

    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(slide.offset, const Offset(0, 2));
    expect(opacity.opacity, 0);
  });
}
