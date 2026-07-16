import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/usecases/archive_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/unarchive_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;

  setUp(() {
    repository = MockAccountRepository();
    when(() => repository.setArchived(any(), archived: any(named: 'archived')))
        .thenAnswer((_) async => const Right(unit));
  });

  test('HU-07: archivar marca la cuenta como archivada', () async {
    final result = await ArchiveAccount(repository)('acc-1');

    expect(result.isRight(), isTrue);
    verify(() => repository.setArchived('acc-1', archived: true)).called(1);
  });

  test('HU-07: desarchivar la devuelve a la lista activa', () async {
    final result = await UnarchiveAccount(repository)('acc-1');

    expect(result.isRight(), isTrue);
    verify(() => repository.setArchived('acc-1', archived: false)).called(1);
  });

  test('archivar no borra: nunca toca el borrado lógico', () async {
    await ArchiveAccount(repository)('acc-1');

    verifyNever(() => repository.softDeleteAccount(any()));
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.setArchived(any(), archived: any(named: 'archived')))
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await ArchiveAccount(repository)('acc-1');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
