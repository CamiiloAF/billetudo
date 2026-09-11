import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/get_legal_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'legal_documents_repository_mock.dart';

void main() {
  test('delegates to the repository', () async {
    final repository = MockLegalDocumentsRepository();
    final manifest = LegalManifest.bundledFallback();
    when(repository.getManifest).thenAnswer((_) async => Right(manifest));
    final getLegalManifest = GetLegalManifest(repository);

    final result = await getLegalManifest();

    expect(
      result.getOrElse((_) => throw StateError('expected Right')),
      manifest,
    );
    verify(repository.getManifest).called(1);
  });
}
