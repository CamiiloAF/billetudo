import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/usecases/create_tag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transaction_fixtures.dart';
import 'transaction_repository_mock.dart';

void main() {
  late MockTagRepository repository;
  late CreateTag createTag;

  setUp(() {
    repository = MockTagRepository();
    createTag = CreateTag(repository);
  });

  test('HU-07: crea una etiqueta nueva cuando no existe otra con ese nombre',
      () async {
    when(() => repository.findTagByName('viaje'))
        .thenAnswer((_) async => const Right(null));
    when(() => repository.createTag('viaje'))
        .thenAnswer((_) async => Right(buildTag()));

    final result = await createTag('  viaje  ');

    expect(result.isRight(), isTrue);
    verify(() => repository.createTag('viaje')).called(1);
  });

  test('HU-07: reutiliza una etiqueta existente en vez de duplicarla',
      () async {
    final existing = buildTag();
    when(() => repository.findTagByName('Viaje'))
        .thenAnswer((_) async => Right(existing));

    final result = await createTag('Viaje');

    expect(result.getRight().toNullable(), existing);
    verifyNever(() => repository.createTag(any()));
  });

  test('rechaza un nombre vacío sin llamar al repositorio', () async {
    final result = await createTag('   ');

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.findTagByName(any()));
    verifyNever(() => repository.createTag(any()));
  });

  test('rechaza un nombre de más de 60 caracteres', () async {
    final result = await createTag('a' * 61);

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.createTag(any()));
  });

  test('propaga el fallo del repositorio en la búsqueda previa', () async {
    when(() => repository.findTagByName(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('disco lleno')),
    );

    final result = await createTag('viaje');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
