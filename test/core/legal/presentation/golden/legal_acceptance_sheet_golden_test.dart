import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/core/legal/domain/repositories/legal_documents_repository.dart';
import 'package:billetudo/core/legal/domain/usecases/accept_legal_documents.dart';
import 'package:billetudo/core/legal/domain/usecases/get_legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/presentation/cubit/legal_acceptance_cubit.dart';
import 'package:billetudo/core/legal/presentation/widgets/sheets/legal_acceptance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockLegalDocumentsRepository extends Mock
    implements LegalDocumentsRepository {}

/// Golden coverage for the just-in-time acceptance sheet shared by
/// "Comenzar" and "Ya tengo cuenta" (Pencil `TxoKJ`, AC 2/3): one visual
/// state — both documents listed, "Acepto" enabled — since that is the only
/// state a user ever sees (already-accepted resolves before any sheet
/// renders, see the widget test).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(LegalDocumentKind.privacyPolicy);
  });

  tearDown(getIt.reset);

  LegalManifest manifest() => LegalManifest(
        currentVersion: 1,
        minAppVersion: '1.0.0',
        documents: [
          for (final kind in LegalDocumentKind.values)
            LegalManifestDocument(
              kind: kind,
              url: 'https://example.com/${kind.name}',
              changedInVersion: 1,
              effectiveDate: DateTime.utc(2026, 1, 1),
            ),
        ],
      );

  LegalDocument document(LegalDocumentKind kind) => LegalDocument(
        kind: kind,
        content: 'contenido',
        legalVersion: 1,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: LegalDocumentSource.bundle,
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('hoja de aceptacion con ambos documentos ($suffix)',
        (tester) async {
      final repository = MockLegalDocumentsRepository();
      when(repository.getManifest).thenAnswer((_) async => Right(manifest()));
      when(repository.getAcceptedVersion)
          .thenAnswer((_) async => const Right(0));
      when(() => repository.resolveDocument(any())).thenAnswer(
        (invocation) async => Right(
          document(invocation.positionalArguments.first as LegalDocumentKind),
        ),
      );
      getIt.registerFactory<LegalAcceptanceCubit>(
        () => LegalAcceptanceCubit(
          ResolveLegalDocument(repository),
          AcceptLegalDocuments(repository),
          GetLegalManifest(repository),
          repository,
        ),
      );

      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LegalAcceptanceSheet.showIfNeeded(context),
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
        matchesGoldenFile('goldens/legal_acceptance_sheet_$suffix.png'),
      );
    });
  }
}
