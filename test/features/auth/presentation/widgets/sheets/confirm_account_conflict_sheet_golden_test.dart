import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_account_conflict_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/golden_helpers.dart';

/// Account-conflict detection on login (the inverse of HU-04): the blocking
/// confirmation sheet shown when a Google/Apple sign-in exchanges a session
/// for a device that already holds local data owned by a *different*
/// account. A single business state — no data variance, since the sheet's
/// whole point is a generic message that never names or hints at which
/// account owns the conflicting data (see `confirm_account_conflict_sheet_test.dart`
/// for that assertion at the widget level).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmAccountConflictSheet.show(context),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/confirm_account_conflict_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('conflicto de cuenta, bloqueante ($suffix)', (tester) async {
      await golden(tester, suffix, brightness: brightness);
    });
  }
}
