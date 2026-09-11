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

import '../../../../../features/auth/presentation/widgets/pump_widget.dart';

class MockLegalDocumentsRepository extends Mock
    implements LegalDocumentsRepository {}

void main() {
  late MockLegalDocumentsRepository repository;

  LegalManifest manifest({required int currentVersion}) => LegalManifest(
        currentVersion: currentVersion,
        minAppVersion: '1.0.0',
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

  LegalDocument document(LegalDocumentKind kind) => LegalDocument(
        kind: kind,
        content: 'contenido',
        legalVersion: 1,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: LegalDocumentSource.bundle,
      );

  setUpAll(() => registerFallbackValue(LegalDocumentKind.privacyPolicy));

  setUp(() {
    repository = MockLegalDocumentsRepository();
    getIt.registerFactory<LegalAcceptanceCubit>(
      () => LegalAcceptanceCubit(
        ResolveLegalDocument(repository),
        AcceptLegalDocuments(repository),
        GetLegalManifest(repository),
        repository,
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets(
      'muestra los dos documentos y solo continua (true) tras tocar Acepto',
      (tester) async {
    when(repository.getManifest)
        .thenAnswer((_) async => Right(manifest(currentVersion: 1)));
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(0));
    when(() => repository.resolveDocument(any())).thenAnswer(
      (invocation) async => Right(
          document(invocation.positionalArguments.first as LegalDocumentKind)),
    );
    when(
      () => repository.acceptLegalDocuments(
        version: any(named: 'version'),
        acceptedAt: any(named: 'acceptedAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await LegalAcceptanceSheet.showIfNeeded(context);
          },
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Acepto los términos y la política'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    verify(
      () => repository.acceptLegalDocuments(
        version: 1,
        acceptedAt: any(named: 'acceptedAt'),
      ),
    ).called(1);
  });

  testWidgets(
      'no muestra ninguna hoja cuando la version vigente ya fue aceptada',
      (tester) async {
    when(repository.getManifest)
        .thenAnswer((_) async => Right(manifest(currentVersion: 2)));
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(2));

    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await LegalAcceptanceSheet.showIfNeeded(context);
          },
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(LegalAcceptanceSheet), findsNothing);
    verifyNever(() => repository.resolveDocument(any()));
  });

  testWidgets('tocar Ahora no resuelve false y no registra aceptacion',
      (tester) async {
    when(repository.getManifest)
        .thenAnswer((_) async => Right(manifest(currentVersion: 1)));
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(0));
    when(() => repository.resolveDocument(any())).thenAnswer(
      (invocation) async => Right(
          document(invocation.positionalArguments.first as LegalDocumentKind)),
    );

    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await LegalAcceptanceSheet.showIfNeeded(context);
          },
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    verifyNever(
      () => repository.acceptLegalDocuments(
        version: any(named: 'version'),
        acceptedAt: any(named: 'acceptedAt'),
      ),
    );
  });
}
