import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/usecases/set_transaction_tags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'transaction_repository_mock.dart';

void main() {
  test('HU-07: delega el reemplazo del conjunto de etiquetas al repositorio',
      () async {
    final repository = MockTransactionRepository();
    when(() => repository.setTransactionTags('tx-1', ['tag-1', 'tag-2']))
        .thenAnswer((_) async => const Right(unit));
    final setTransactionTags = SetTransactionTags(repository);

    final result = await setTransactionTags('tx-1', ['tag-1', 'tag-2']);

    expect(result.isRight(), isTrue);
    verify(() => repository.setTransactionTags('tx-1', ['tag-1', 'tag-2']))
        .called(1);
  });
}
