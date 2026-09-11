import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/accept_legal_documents.dart';
import 'package:billetudo/core/legal/domain/usecases/get_legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/presentation/cubit/legal_acceptance_cubit.dart';
import 'package:billetudo/core/legal/presentation/cubit/legal_acceptance_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/usecases/legal_documents_repository_mock.dart';

void main() {
  late MockLegalDocumentsRepository repository;
  late ResolveLegalDocument resolveLegalDocument;
  late AcceptLegalDocuments acceptLegalDocuments;
  late GetLegalManifest getLegalManifest;

  LegalDocument document(LegalDocumentKind kind, {int version = 1}) =>
      LegalDocument(
        kind: kind,
        content: 'contenido',
        legalVersion: version,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: LegalDocumentSource.bundle,
      );

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

  setUpAll(() {
    registerFallbackValue(LegalDocumentKind.privacyPolicy);
  });

  setUp(() {
    repository = MockLegalDocumentsRepository();
    resolveLegalDocument = ResolveLegalDocument(repository);
    acceptLegalDocuments = AcceptLegalDocuments(repository);
    getLegalManifest = GetLegalManifest(repository);
  });

  LegalAcceptanceCubit build() => LegalAcceptanceCubit(
        resolveLegalDocument,
        acceptLegalDocuments,
        getLegalManifest,
        repository,
      );

  blocTest<LegalAcceptanceCubit, LegalAcceptanceState>(
    'load resuelve ambos documentos cuando la version aceptada esta '
    'desactualizada',
    build: build,
    setUp: () {
      when(repository.getManifest)
          .thenAnswer((_) async => Right(manifest(currentVersion: 1)));
      when(repository.getAcceptedVersion)
          .thenAnswer((_) async => const Right(0));
      when(() => repository.resolveDocument(any())).thenAnswer(
        (invocation) async => Right(document(
            invocation.positionalArguments.first as LegalDocumentKind)),
      );
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.alreadyAccepted, isFalse);
      expect(cubit.state.documents, hasLength(2));
      expect(cubit.state.status, LegalAcceptanceStatus.ready);
    },
  );

  blocTest<LegalAcceptanceCubit, LegalAcceptanceState>(
    'load marca alreadyAccepted sin resolver documentos cuando la version '
    'aceptada ya cubre la vigente',
    build: build,
    setUp: () {
      when(repository.getManifest)
          .thenAnswer((_) async => Right(manifest(currentVersion: 2)));
      when(repository.getAcceptedVersion)
          .thenAnswer((_) async => const Right(2));
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.alreadyAccepted, isTrue);
      verifyNever(() => repository.resolveDocument(any()));
    },
  );

  blocTest<LegalAcceptanceCubit, LegalAcceptanceState>(
    'accept registra la aceptacion con los documentos ya resueltos',
    build: build,
    setUp: () {
      when(repository.getManifest)
          .thenAnswer((_) async => Right(manifest(currentVersion: 1)));
      when(repository.getAcceptedVersion)
          .thenAnswer((_) async => const Right(0));
      when(() => repository.resolveDocument(any())).thenAnswer(
        (invocation) async => Right(document(
            invocation.positionalArguments.first as LegalDocumentKind)),
      );
      when(
        () => repository.acceptLegalDocuments(
          version: any(named: 'version'),
          acceptedAt: any(named: 'acceptedAt'),
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.accept();
    },
    verify: (cubit) {
      expect(cubit.state.status, LegalAcceptanceStatus.accepted);
      verify(
        () => repository.acceptLegalDocuments(
          version: 1,
          acceptedAt: any(named: 'acceptedAt'),
        ),
      ).called(1);
    },
  );
}
