import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/repositories/auth_repository.dart';
import 'package:billetudo/features/auth/domain/usecases/cancel_account_conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late CancelAccountConflict useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = CancelAccountConflict(repository);
  });

  test('delega en AuthRepository.cancelAccountConflict y devuelve su Right',
      () async {
    when(() => repository.cancelAccountConflict())
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase();

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.cancelAccountConflict()).called(1);
  });

  test('propaga el Left del repositorio sin transformarlo', () async {
    const failure = NetworkFailure('no se pudo cerrar sesión');
    when(() => repository.cancelAccountConflict())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left<Failure, Unit>(failure));
  });
}
