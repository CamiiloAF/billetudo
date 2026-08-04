import 'package:billetudo/features/onboarding/presentation/pages/backup_intro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-07 (`MydOr`/`DfHXL`): "Respalda tus datos" — informative screen with a
/// single business state (no cubit, no data variants) — "Activar
/// respaldo"/"Después".
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
    await pumpGolden(
      tester,
      BackupIntroPage(onActivarRespaldo: () {}, onDespues: () {}),
      brightness: brightness,
    );
    await expectLater(
      find.byType(BackupIntroPage),
      matchesGoldenFile('goldens/backup_intro_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('backup intro ($suffix)', (tester) async {
      await golden(tester, suffix, brightness: brightness);
    });
  }
}
