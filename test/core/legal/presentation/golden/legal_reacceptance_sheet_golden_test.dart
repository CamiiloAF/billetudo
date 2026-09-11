import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/accept_legal_documents.dart';
import 'package:billetudo/core/legal/domain/usecases/get_changed_legal_documents.dart';
import 'package:billetudo/core/legal/domain/usecases/get_legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/domain/usecases/should_show_reacceptance.dart';
import 'package:billetudo/core/legal/presentation/cubit/legal_reacceptance_cubit.dart';
import 'package:billetudo/core/legal/presentation/widgets/sheets/legal_reacceptance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../support/golden_helpers.dart';
import '../../domain/usecases/legal_documents_repository_mock.dart';

/// Golden coverage for the mandatory re-acceptance sheet (Pencil
/// `JHwhG`/`X2781z` step 1, `f8KnrT` step 2, AC 8-10): both-changed and
/// single-changed copy for step 1 (AC 9 requires singular copy for the
/// one-document case), plus step 2's consequence + export escape hatch.
void main() {
  late MockLegalDocumentsRepository repository;

  LegalDocument document(LegalDocumentKind kind) => LegalDocument(
        kind: kind,
        content: 'contenido',
        legalVersion: 2,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: LegalDocumentSource.bundle,
      );

  LegalManifest manifest({required Map<LegalDocumentKind, int> changed}) =>
      LegalManifest(
        currentVersion: 2,
        minAppVersion: '1.0.0',
        documents: [
          for (final kind in LegalDocumentKind.values)
            LegalManifestDocument(
              kind: kind,
              url: 'https://example.com/${kind.name}',
              changedInVersion: changed[kind] ?? 1,
              effectiveDate: DateTime.utc(2026, 1, 1),
            ),
        ],
      );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(LegalDocumentKind.privacyPolicy);
    PackageInfo.setMockInitialValues(
      appName: 'billetudo',
      packageName: 'com.billetudo.app',
      version: '1.5.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    repository = MockLegalDocumentsRepository();
  });

  LegalReacceptanceCubit buildCubit() => LegalReacceptanceCubit(
        GetLegalManifest(repository),
        repository,
        const ShouldShowReacceptance(),
        const GetChangedLegalDocuments(),
        ResolveLegalDocument(repository),
        AcceptLegalDocuments(repository),
      );

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required Map<LegalDocumentKind, int> changed,
    bool step2 = false,
  }) async {
    when(repository.getManifest)
        .thenAnswer((_) async => Right(manifest(changed: changed)));
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(1));
    when(() => repository.resolveDocument(any())).thenAnswer(
      (invocation) async => Right(
        document(invocation.positionalArguments.first as LegalDocumentKind),
      ),
    );

    final cubit = buildCubit();
    await cubit.checkOnLaunch();
    if (step2) {
      cubit.goToDeclineConsequence();
    }

    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        BlocProvider.value(
          value: cubit,
          child: const LegalReacceptanceSheet(),
        ),
        brightness: brightness,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/legal_reacceptance_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('paso 1, ambos documentos cambiaron ($suffix)', (tester) async {
      await golden(
        tester,
        'step1_both_$suffix',
        brightness: brightness,
        changed: {
          LegalDocumentKind.termsOfUse: 2,
          LegalDocumentKind.privacyPolicy: 2,
        },
      );
    });

    testWidgets('paso 1, solo terminos de uso cambio (copy singular) ($suffix)',
        (tester) async {
      await golden(
        tester,
        'step1_single_$suffix',
        brightness: brightness,
        changed: {LegalDocumentKind.termsOfUse: 2},
      );
    });

    testWidgets('paso 2, consecuencia y boton de exportar ($suffix)',
        (tester) async {
      await golden(
        tester,
        'step2_$suffix',
        brightness: brightness,
        changed: {
          LegalDocumentKind.termsOfUse: 2,
          LegalDocumentKind.privacyPolicy: 2,
        },
        step2: true,
      );
    });
  }
}
