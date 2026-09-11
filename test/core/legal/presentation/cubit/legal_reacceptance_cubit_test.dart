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
import 'package:billetudo/core/legal/presentation/cubit/legal_reacceptance_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/usecases/legal_documents_repository_mock.dart';

void main() {
  late MockLegalDocumentsRepository repository;
  late GetLegalManifest getLegalManifest;
  late ResolveLegalDocument resolveLegalDocument;
  late AcceptLegalDocuments acceptLegalDocuments;

  LegalDocument document(LegalDocumentKind kind, {int version = 2}) =>
      LegalDocument(
        kind: kind,
        content: 'contenido',
        legalVersion: version,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: LegalDocumentSource.bundle,
      );

  LegalManifest manifest({
    required int currentVersion,
    required String minAppVersion,
    Map<LegalDocumentKind, int>? changedInVersion,
  }) =>
      LegalManifest(
        currentVersion: currentVersion,
        minAppVersion: minAppVersion,
        documents: [
          for (final kind in LegalDocumentKind.values)
            LegalManifestDocument(
              kind: kind,
              url: 'https://example.com/${kind.name}',
              changedInVersion: changedInVersion?[kind] ?? currentVersion,
              effectiveDate: DateTime.utc(2026, 1, 1),
            ),
        ],
      );

  setUpAll(() {
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
    getLegalManifest = GetLegalManifest(repository);
    resolveLegalDocument = ResolveLegalDocument(repository);
    acceptLegalDocuments = AcceptLegalDocuments(repository);
  });

  LegalReacceptanceCubit build() => LegalReacceptanceCubit(
        getLegalManifest,
        repository,
        const ShouldShowReacceptance(),
        const GetChangedLegalDocuments(),
        resolveLegalDocument,
        acceptLegalDocuments,
      );

  test(
    'checkOnLaunch pasa a step1 cuando la version esta desactualizada Y la '
    'app cumple minAppVersion',
    () async {
      when(repository.getManifest).thenAnswer(
        (_) async => Right(
          manifest(currentVersion: 2, minAppVersion: '1.0.0'),
        ),
      );
      when(repository.getAcceptedVersion)
          .thenAnswer((_) async => const Right(1));
      when(() => repository.resolveDocument(any())).thenAnswer(
        (invocation) async => Right(
          document(invocation.positionalArguments.first as LegalDocumentKind),
        ),
      );

      final cubit = build();
      await cubit.checkOnLaunch();

      expect(cubit.state.status, LegalReacceptanceStatus.step1);
      expect(cubit.state.changedDocuments, hasLength(2));
    },
  );

  test(
    'checkOnLaunch se queda idle cuando la version instalada no cumple '
    'minAppVersion, aunque la version aceptada esté desactualizada',
    () async {
      when(repository.getManifest).thenAnswer(
        (_) async => Right(
          manifest(currentVersion: 2, minAppVersion: '9.0.0'),
        ),
      );
      when(repository.getAcceptedVersion)
          .thenAnswer((_) async => const Right(1));

      final cubit = build();
      await cubit.checkOnLaunch();

      expect(cubit.state.status, LegalReacceptanceStatus.idle);
      verifyNever(() => repository.resolveDocument(any()));
    },
  );

  test(
      'checkOnLaunch solo corre una vez por instancia (una sola vez por '
      'arranque)', () async {
    when(repository.getManifest).thenAnswer(
      (_) async => Right(manifest(currentVersion: 2, minAppVersion: '1.0.0')),
    );
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(1));
    when(() => repository.resolveDocument(any())).thenAnswer(
      (invocation) async => Right(
        document(invocation.positionalArguments.first as LegalDocumentKind),
      ),
    );

    final cubit = build();
    await cubit.checkOnLaunch();
    await cubit.checkOnLaunch();

    verify(repository.getManifest).called(1);
  });

  test(
      'goToDeclineConsequence y backToStep1 alternan el paso sin perder '
      'los documentos', () async {
    when(repository.getManifest).thenAnswer(
      (_) async => Right(manifest(currentVersion: 2, minAppVersion: '1.0.0')),
    );
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(1));
    when(() => repository.resolveDocument(any())).thenAnswer(
      (invocation) async => Right(
        document(invocation.positionalArguments.first as LegalDocumentKind),
      ),
    );

    final cubit = build();
    await cubit.checkOnLaunch();

    cubit.goToDeclineConsequence();
    expect(cubit.state.status, LegalReacceptanceStatus.step2);
    expect(cubit.state.changedDocuments, hasLength(2));

    cubit.backToStep1();
    expect(cubit.state.status, LegalReacceptanceStatus.step1);
    expect(cubit.state.changedDocuments, hasLength(2));
  });

  test('accept registra la aceptacion y vuelve a idle', () async {
    when(repository.getManifest).thenAnswer(
      (_) async => Right(manifest(currentVersion: 2, minAppVersion: '1.0.0')),
    );
    when(repository.getAcceptedVersion).thenAnswer((_) async => const Right(1));
    when(() => repository.resolveDocument(any())).thenAnswer(
      (invocation) async => Right(
        document(invocation.positionalArguments.first as LegalDocumentKind),
      ),
    );
    when(
      () => repository.acceptLegalDocuments(
        version: any(named: 'version'),
        acceptedAt: any(named: 'acceptedAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    final cubit = build();
    await cubit.checkOnLaunch();
    final accepted = await cubit.accept();

    expect(accepted, isTrue);
    expect(cubit.state.status, LegalReacceptanceStatus.idle);
    verify(
      () => repository.acceptLegalDocuments(
        version: 2,
        acceptedAt: any(named: 'acceptedAt'),
      ),
    ).called(1);
  });
}
