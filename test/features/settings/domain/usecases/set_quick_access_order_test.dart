import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:billetudo/features/settings/domain/usecases/set_quick_access_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late SetQuickAccessOrder setQuickAccessOrder;

  setUp(() {
    repository = MockAppSettingsRepository();
    setQuickAccessOrder = SetQuickAccessOrder(repository);
  });

  const validOrder = [
    QuickAccessItem.debts,
    QuickAccessItem.reports,
    QuickAccessItem.scheduledPayments,
  ];

  test('persists a valid permutation by delegating to the repository', () async {
    when(() => repository.setQuickAccessOrder(validOrder))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await setQuickAccessOrder(validOrder);

    expect(result.isRight(), isTrue);
    verify(() => repository.setQuickAccessOrder(validOrder)).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.setQuickAccessOrder(validOrder)).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await setQuickAccessOrder(validOrder);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });

  test(
    'rejects a duplicate item without writing to the repository',
    () async {
      const invalidOrder = [
        QuickAccessItem.debts,
        QuickAccessItem.debts,
        QuickAccessItem.reports,
      ];

      final result = await setQuickAccessOrder(invalidOrder);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repository.setQuickAccessOrder(any()));
    },
  );

  test(
    'rejects an incomplete list (missing an item) without writing',
    () async {
      const invalidOrder = [
        QuickAccessItem.debts,
        QuickAccessItem.reports,
      ];

      final result = await setQuickAccessOrder(invalidOrder);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repository.setQuickAccessOrder(any()));
    },
  );

  test('rejects an empty list without writing', () async {
    final result = await setQuickAccessOrder(const []);

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.setQuickAccessOrder(any()));
  });
}
