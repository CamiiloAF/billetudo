import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/should_show_reacceptance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ShouldShowReacceptance shouldShowReacceptance;

  LegalManifest manifest({
    required int currentVersion,
    required String minAppVersion,
  }) =>
      LegalManifest(
        currentVersion: currentVersion,
        minAppVersion: minAppVersion,
        documents: [
          for (final kind in LegalDocumentKind.values)
            LegalManifestDocument(
              kind: kind,
              url: 'https://example.com/${kind.name}',
              changedInVersion: currentVersion,
              effectiveDate: DateTime.utc(2026, 1, 1),
            ),
        ],
      );

  setUp(() {
    shouldShowReacceptance = const ShouldShowReacceptance();
  });

  test(
    'shows the sheet when the accepted version is outdated AND the app '
    'satisfies minAppVersion',
    () {
      final result = shouldShowReacceptance(
        acceptedVersion: 1,
        manifest: manifest(currentVersion: 2, minAppVersion: '1.4.0'),
        installedAppVersion: '1.5.0',
      );

      expect(result, isTrue);
    },
  );

  test(
    'does not show the sheet when the accepted version is already current, '
    'even if the app satisfies minAppVersion',
    () {
      final result = shouldShowReacceptance(
        acceptedVersion: 2,
        manifest: manifest(currentVersion: 2, minAppVersion: '1.4.0'),
        installedAppVersion: '1.5.0',
      );

      expect(result, isFalse);
    },
  );

  test(
    'does not show the sheet when the version is outdated but the installed '
    'app does not satisfy minAppVersion — someone who has not updated must '
    'not be asked about functionality they do not have',
    () {
      final result = shouldShowReacceptance(
        acceptedVersion: 1,
        manifest: manifest(currentVersion: 2, minAppVersion: '1.4.0'),
        installedAppVersion: '1.3.9',
      );

      expect(result, isFalse);
    },
  );

  test('an exact match on minAppVersion counts as satisfying it', () {
    final result = shouldShowReacceptance(
      acceptedVersion: 1,
      manifest: manifest(currentVersion: 2, minAppVersion: '1.4.0'),
      installedAppVersion: '1.4.0',
    );

    expect(result, isTrue);
  });

  test('compares semver numerically, not lexicographically (1.10.0 > 1.9.0)',
      () {
    final result = shouldShowReacceptance(
      acceptedVersion: 1,
      manifest: manifest(currentVersion: 2, minAppVersion: '1.9.0'),
      installedAppVersion: '1.10.0',
    );

    expect(result, isTrue);
  });
}
