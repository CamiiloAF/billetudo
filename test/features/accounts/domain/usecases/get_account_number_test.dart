import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/usecases/get_account_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late GetAccountNumber getAccountNumber;

  setUp(() {
    repository = MockAccountRepository();
    getAccountNumber = GetAccountNumber(repository);
  });

  test('HU-03: lee el número completo del almacén seguro', () async {
    when(() => repository.readAccountNumber('acc-1'))
        .thenAnswer((_) async => const Right('1234567890124321'));

    final result = await getAccountNumber('acc-1');

    expect(result.getRight().toNullable(), '1234567890124321');
  });

  test('una cuenta sin número guardado devuelve null, no un fallo', () async {
    when(() => repository.readAccountNumber('acc-1'))
        .thenAnswer((_) async => const Right(null));

    final result = await getAccountNumber('acc-1');

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable(), isNull);
  });

  test('propaga SecureStorageFailure si el Keychain/Keystore falla', () async {
    when(() => repository.readAccountNumber('acc-1')).thenAnswer(
      (_) async => const Left(SecureStorageFailure('keychain bloqueado')),
    );

    final result = await getAccountNumber('acc-1');

    expect(result.getLeft().toNullable(), isA<SecureStorageFailure>());
  });
}
