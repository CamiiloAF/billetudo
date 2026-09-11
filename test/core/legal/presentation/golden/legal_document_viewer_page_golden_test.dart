import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockResolveLegalDocument extends Mock implements ResolveLegalDocument {}

/// Golden coverage for the native document viewer (Pencil `wwNqS`): one case
/// per [LegalDocumentSource] the version/date line can reflect — cache and
/// bundle both render, since AC 6 requires the line to always match what is
/// actually shown, never the manifest's declared current version.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(LegalDocumentKind.privacyPolicy);
  });

  tearDown(getIt.reset);

  const content = '# Términos de uso\n\n'
      'Estos términos regulan el uso de la aplicación Billetudo.\n\n'
      '## 1. Aceptación\n\n'
      'Al usar la aplicación aceptas estos **términos**.\n\n'
      '## 2. Uso permitido\n\n'
      'Debes usar la aplicación de forma responsable y conforme a la ley.';

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required LegalDocumentSource source,
  }) async {
    final resolveLegalDocument = MockResolveLegalDocument();
    when(() => resolveLegalDocument(kind: LegalDocumentKind.termsOfUse))
        .thenAnswer(
      (_) async => Right(
        LegalDocument(
          kind: LegalDocumentKind.termsOfUse,
          content: content,
          legalVersion: source == LegalDocumentSource.cache ? 3 : 1,
          effectiveDate: DateTime.utc(2026, 8, 15),
          source: source,
        ),
      ),
    );
    getIt.registerFactory<ResolveLegalDocument>(() => resolveLegalDocument);

    await pumpGolden(
      tester,
      const LegalDocumentViewerPage(kind: LegalDocumentKind.termsOfUse),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1000),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/legal_document_viewer_page_${name}_'
          '${brightness == Brightness.light ? 'light' : 'dark'}.png'),
    );
    await getIt.reset();
  }

  for (final brightness in Brightness.values) {
    testWidgets('documento servido desde cache', (tester) async {
      await golden(
        tester,
        'cache',
        brightness: brightness,
        source: LegalDocumentSource.cache,
      );
    });

    testWidgets('documento servido desde el bundle empaquetado',
        (tester) async {
      await golden(
        tester,
        'bundle',
        brightness: brightness,
        source: LegalDocumentSource.bundle,
      );
    });
  }
}
