import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'transaction_repository_mock.dart';

void main() {
  late MockTransactionRepository repository;

  setUp(() {
    repository = MockTransactionRepository();
  });

  group('DeleteTransaction (HU-05)', () {
    test('delega el borrado lógico al repositorio', () async {
      when(() => repository.deleteTransaction('tx-1'))
          .thenAnswer((_) async => const Right(unit));
      final deleteTransaction = DeleteTransaction(repository);

      final result = await deleteTransaction('tx-1');

      expect(result.isRight(), isTrue);
      verify(() => repository.deleteTransaction('tx-1')).called(1);
    });

    test('propaga el fallo del repositorio', () async {
      when(() => repository.deleteTransaction('tx-1')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no existe')),
      );
      final deleteTransaction = DeleteTransaction(repository);

      final result = await deleteTransaction('tx-1');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('RestoreTransaction (HU-05)', () {
    test('delega el "Deshacer" al repositorio', () async {
      when(() => repository.restoreTransaction('tx-1'))
          .thenAnswer((_) async => const Right(unit));
      final restoreTransaction = RestoreTransaction(repository);

      final result = await restoreTransaction('tx-1');

      expect(result.isRight(), isTrue);
      verify(() => repository.restoreTransaction('tx-1')).called(1);
    });
  });
}
