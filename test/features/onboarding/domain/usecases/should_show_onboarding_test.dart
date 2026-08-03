import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/onboarding/domain/usecases/should_show_onboarding.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/domain/usecases/account_repository_mock.dart';
import '../../../settings/domain/usecases/app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository settingsRepository;
  late MockAccountRepository accountRepository;
  late ShouldShowOnboarding shouldShowOnboarding;

  AppSettings settings({required bool onboardingCompleted}) => AppSettings(
        zeroBasedEnabled: false,
        categoriesSeeded: true,
        onboardingCompleted: onboardingCompleted,
      );

  AccountWithBalance activeAccount() {
    final account = Account(
      id: 'acc-1',
      name: 'Ahorros',
      type: AccountType.savings,
      currency: 'COP',
      initialBalanceMinor: 0,
      archived: false,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    );
    return AccountWithBalance(
      account: account,
      balance: AccountBalance.fromBalance(account: account, balanceMinor: 0),
    );
  }

  setUp(() {
    settingsRepository = MockAppSettingsRepository();
    accountRepository = MockAccountRepository();
    shouldShowOnboarding =
        ShouldShowOnboarding(settingsRepository, accountRepository);
  });

  test('returns false without touching accounts when the latch is already on',
      () async {
    when(() => settingsRepository.getSettings()).thenAnswer(
      (_) async => Right(settings(onboardingCompleted: true)),
    );

    final result = await shouldShowOnboarding();

    expect(result.getRight().toNullable(), isFalse);
    verifyNever(() => accountRepository.watchActiveAccounts());
    verifyNever(() => settingsRepository.markOnboardingCompleted());
  });

  test('returns true when the latch is off and there are no active accounts',
      () async {
    when(() => settingsRepository.getSettings()).thenAnswer(
      (_) async => Right(settings(onboardingCompleted: false)),
    );
    when(() => accountRepository.watchActiveAccounts())
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));

    final result = await shouldShowOnboarding();

    expect(result.getRight().toNullable(), isTrue);
    verifyNever(() => settingsRepository.markOnboardingCompleted());
  });

  test(
      'returns true when the latch is off and every account is tombstoned '
      '(watchActiveAccounts already excludes them, so this looks identical to '
      'having no accounts at all)', () async {
    when(() => settingsRepository.getSettings()).thenAnswer(
      (_) async => Right(settings(onboardingCompleted: false)),
    );
    when(() => accountRepository.watchActiveAccounts())
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));

    final result = await shouldShowOnboarding();

    expect(result.getRight().toNullable(), isTrue);
  });

  test(
      'silently latches onboardingCompleted and returns false when an active '
      'account already exists (pre-flag install or restore)', () async {
    when(() => settingsRepository.getSettings()).thenAnswer(
      (_) async => Right(settings(onboardingCompleted: false)),
    );
    when(() => accountRepository.watchActiveAccounts()).thenAnswer(
      (_) => Stream.value(Right(<AccountWithBalance>[activeAccount()])),
    );
    when(() => settingsRepository.markOnboardingCompleted())
        .thenAnswer((_) async => const Right(unit));

    final result = await shouldShowOnboarding();

    expect(result.getRight().toNullable(), isFalse);
    verify(() => settingsRepository.markOnboardingCompleted()).called(1);
  });

  test('propagates a failure reading settings', () async {
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await shouldShowOnboarding();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    verifyNever(() => accountRepository.watchActiveAccounts());
  });

  test('propagates a failure reading accounts', () async {
    when(() => settingsRepository.getSettings()).thenAnswer(
      (_) async => Right(settings(onboardingCompleted: false)),
    );
    when(() => accountRepository.watchActiveAccounts()).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('sin disco'))),
    );

    final result = await shouldShowOnboarding();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    verifyNever(() => settingsRepository.markOnboardingCompleted());
  });

  test('propagates a failure latching the flag', () async {
    when(() => settingsRepository.getSettings()).thenAnswer(
      (_) async => Right(settings(onboardingCompleted: false)),
    );
    when(() => accountRepository.watchActiveAccounts()).thenAnswer(
      (_) => Stream.value(Right(<AccountWithBalance>[activeAccount()])),
    );
    when(() => settingsRepository.markOnboardingCompleted()).thenAnswer(
      (_) async => const Left(DatabaseFailure('sin disco')),
    );

    final result = await shouldShowOnboarding();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
