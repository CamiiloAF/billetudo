import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/keyboard_done_toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, {required FocusNode focusNode}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: KeyboardDoneToolbar(
            child: TextField(
              focusNode: focusNode,
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'iOS: shows the "Listo" bar while focused and hides it on unfocus',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    try {
      await pumpField(tester, focusNode: focusNode);

      expect(find.text('Listo'), findsNothing);

      focusNode.requestFocus();
      await tester.pump();
      expect(find.text('Listo'), findsOneWidget);

      focusNode.unfocus();
      await tester.pump();
      expect(find.text('Listo'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS: tapping "Listo" dismisses the keyboard by dropping focus',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    try {
      await pumpField(tester, focusNode: focusNode);

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.text('Listo'));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
      expect(find.text('Listo'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('off iOS: never shows the bar', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    try {
      await pumpField(tester, focusNode: focusNode);

      focusNode.requestFocus();
      await tester.pump();

      expect(find.text('Listo'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
