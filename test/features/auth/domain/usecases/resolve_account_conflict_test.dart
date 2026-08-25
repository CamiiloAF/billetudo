import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/repositories/auth_repository.dart';
import 'package:billetudo/features/auth/domain/usecases/resolve_account_conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ResolveAccountConflict useCase;

  const user = AuthUser(
    id: 'user-1',
    displayName: 'Ana',
    provider: AuthProvider.google,
  );

  setUp(() {
    repository = MockAuthRepository();
    useCase = ResolveAccountConflict(repository);
  });

  test('delega en AuthRepository.resolveAccountConflict y devuelve su Right',
      () async {
    when(() => repository.resolveAccountConflict())
        .thenAnswer((_) async => const Right(user));

    final result = await useCase();

    expect(result, const Right<Failure, AuthUser>(user));
    verify(() => repository.resolveAccountConflict()).called(1);
  });

  test('propaga el Left del repositorio sin transformarlo', () async {
    const failure = DatabaseFailure('no se pudo borrar');
    when(() => repository.resolveAccountConflict())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left<Failure, AuthUser>(failure));
  });
}
