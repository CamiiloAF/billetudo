import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_tags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transaction_fixtures.dart';
import 'transaction_repository_mock.dart';

void main() {
  test('expone el stream de etiquetas del repositorio', () async {
    final repository = MockTagRepository();
    final tags = [buildTag(), buildTag(id: 'tag-2', name: 'ocio')];
    when(
      repository.watchTags,
    ).thenAnswer((_) => Stream.value(Right(tags)));
    final watchTags = WatchTags(repository);

    final result = await watchTags().first;

    expect(result.getRight().toNullable(), tags);
  });
}
