import 'package:billetudo/features/auth/domain/entities/delete_account_scope.dart';
import 'package:billetudo/features/auth/presentation/pages/account_deleted_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-07 paso 3 (`sqm4I` / `q43mHJ`): the neutral closing screen of account
/// deletion. Three business states now that copy varies by
/// [DeleteAccountScope]: the normal cloud-and-local closing (`cloudAndLocal`),
/// the `localOnlySignedOut` variant that must not claim the cloud account was
/// deleted, and `localOnlyNeverSignedIn` which never mentions the cloud at
/// all because this device's `everSignedIn` flag is local-only and cannot
/// verify one doesn't exist.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  const cases = {
    'cloud_and_local': DeleteAccountScope.cloudAndLocal,
    'local_only_signed_out': DeleteAccountScope.localOnlySignedOut,
    'local_only_never_signed_in': DeleteAccountScope.localOnlyNeverSignedIn,
  };

  for (final brightness in Brightness.values) {
    final brightnessSuffix = brightness == Brightness.light ? 'light' : 'dark';

    for (final entry in cases.entries) {
      testWidgets(
          'account deleted (${entry.key}, $brightnessSuffix)', (tester) async {
        await pumpGolden(
          tester,
          AccountDeletedPage(scope: entry.value, onGoHome: () {}),
          brightness: brightness,
        );
        await expectLater(
          find.byType(AccountDeletedPage),
          matchesGoldenFile(
            'goldens/account_deleted_page_${entry.key}_$brightnessSuffix.png',
          ),
        );
      });
    }
  }
}
