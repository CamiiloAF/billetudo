import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/usecases/delete_all_capture_data.dart';
import 'package:billetudo/features/capture/domain/usecases/discard_captures_before.dart';
import 'package:billetudo/features/capture/domain/usecases/discard_pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/forget_capture_learning.dart';
import 'package:billetudo/features/capture/domain/usecases/learn_merchant_category.dart';
import 'package:billetudo/features/capture/domain/usecases/link_issuer_account.dart';
import 'package:billetudo/features/capture/domain/usecases/purge_discarded_captures.dart';
import 'package:billetudo/features/capture/domain/usecases/restore_pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/suggest_account_for_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/suggest_category_for_merchant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

void main() {
  late MockPendingCaptureRepository repository;
  late MockCaptureLearningRepository learning;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    repository = MockPendingCaptureRepository();
    learning = MockCaptureLearningRepository();
  });

  group('DiscardPendingCapture', () {
    test('records the transaction the user pointed at as the same one',
        () async {
      when(
        () => repository.discardCapture(
          any(),
          duplicateOfTransactionId: any(named: 'duplicateOfTransactionId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      await DiscardPendingCapture(repository)(
        'capture-1',
        duplicateOfTransactionId: 'tx-1',
      );

      verify(
        () => repository.discardCapture(
          'capture-1',
          duplicateOfTransactionId: 'tx-1',
        ),
      ).called(1);
    });
  });

  group('RestorePendingCapture', () {
    test('surfaces the failure when the row was already purged', () async {
      when(() => repository.restoreCapture(any()))
          .thenAnswer((_) async => const Left(NotFoundFailure('purged')));

      final result = await RestorePendingCapture(repository)('capture-1');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('DiscardCapturesBefore', () {
    test('returns the ids it discarded so undo touches only those', () async {
      when(() => repository.discardCapturesBefore(any()))
          .thenAnswer((_) async => const Right(['a', 'b']));

      final cutOff = DateTime(2026, 8, 1);
      final result = await DiscardCapturesBefore(repository)(cutOff);

      expect(result.getOrElse((_) => const []), ['a', 'b']);
      verify(() => repository.discardCapturesBefore(cutOff)).called(1);
    });
  });

  group('PurgeDiscardedCaptures', () {
    test('purges past the undo window and deletes physically', () async {
      when(() => repository.purgeDiscardedCaptures(any()))
          .thenAnswer((_) async => const Right(3));

      final now = DateTime(2026, 9, 1, 12);
      final result = await PurgeDiscardedCaptures(repository)(now: now);

      expect(result.getOrElse((_) => 0), 3);
      verify(
        () => repository.purgeDiscardedCaptures(
          now.subtract(PurgeDiscardedCaptures.undoWindow),
        ),
      ).called(1);
    });

    test('leaves room for the snackbar undo', () {
      expect(
        PurgeDiscardedCaptures.undoWindow,
        greaterThan(const Duration(minutes: 1)),
      );
    });
  });

  group('SuggestAccountForCapture', () {
    late MockIssuerSettingsRepository issuers;
    late SuggestAccountForCapture suggestAccount;

    const wallet = 'com.google.android.apps.walletnfcrel';
    const nu = 'com.nu.production';

    setUp(() {
      issuers = MockIssuerSettingsRepository();
      suggestAccount = SuggestAccountForCapture(repository, issuers);
      when(() => issuers.accountIdForPackage(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => repository.findAccountIdByLast4(any()))
          .thenAnswer((_) async => const Right(null));
    });

    test('resolves the last-4 hint when the issuer sent one', () async {
      when(() => repository.findAccountIdByLast4('5615'))
          .thenAnswer((_) async => const Right('card-account'));

      final result = await suggestAccount(
        sourcePackage: wallet,
        accountHint: '5615',
      );

      expect(result.getOrElse((_) => null), 'card-account');
    });

    // Verified against real notifications: Nu and Nequi never quote the last
    // four digits, so without the issuer link their captures would arrive
    // account-less forever.
    test('uses the issuer link when the issuer sends no hint', () async {
      when(() => issuers.accountIdForPackage(nu))
          .thenAnswer((_) async => const Right('nu-account'));

      final result = await suggestAccount(sourcePackage: nu);

      expect(result.getOrElse((_) => null), 'nu-account');
      verifyNever(() => repository.findAccountIdByLast4(any()));
    });

    test('the hint wins over the issuer link when both resolve', () async {
      when(() => repository.findAccountIdByLast4('5615'))
          .thenAnswer((_) async => const Right('card-account'));
      when(() => issuers.accountIdForPackage(wallet))
          .thenAnswer((_) async => const Right('wallet-account'));

      final result = await suggestAccount(
        sourcePackage: wallet,
        accountHint: '5615',
      );

      expect(result.getOrElse((_) => null), 'card-account');
    });

    test('falls back to the issuer link when the hint matches nothing',
        () async {
      when(() => issuers.accountIdForPackage(wallet))
          .thenAnswer((_) async => const Right('wallet-account'));

      final result = await suggestAccount(
        sourcePackage: wallet,
        accountHint: '0000',
      );

      expect(result.getOrElse((_) => null), 'wallet-account');
    });

    test('suggests nothing when neither path resolves', () async {
      final result = await suggestAccount(
        sourcePackage: nu,
        accountHint: '0000',
      );

      expect(result.getOrElse((_) => 'x'), isNull);
    });
  });

  group('LinkIssuerAccount', () {
    test('stores and clears the issuer to account link', () async {
      final issuers = MockIssuerSettingsRepository();
      when(
        () => issuers.setIssuerAccount(
          packageName: any(named: 'packageName'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      await LinkIssuerAccount(issuers)(
        packageName: 'com.nu.production',
        accountId: 'nu-account',
      );
      await LinkIssuerAccount(issuers)(
        packageName: 'com.nu.production',
        accountId: null,
      );

      verify(
        () => issuers.setIssuerAccount(
          packageName: 'com.nu.production',
          accountId: 'nu-account',
        ),
      ).called(1);
      verify(
        () => issuers.setIssuerAccount(
          packageName: 'com.nu.production',
          accountId: null,
        ),
      ).called(1);
    });
  });

  group('LearnMerchantCategory', () {
    test('stores the normalized key', () async {
      when(
        () => learning.learnMerchantCategory(
          merchantKey: any(named: 'merchantKey'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      await LearnMerchantCategory(learning)(
        merchantRaw: ' Éxito  Calle 80 ',
        categoryId: 'category-1',
      );

      verify(
        () => learning.learnMerchantCategory(
          merchantKey: 'EXITO CALLE 80',
          categoryId: 'category-1',
        ),
      ).called(1);
    });

    test('learns nothing from a confirmation with no category', () async {
      final result = await LearnMerchantCategory(learning)(
        merchantRaw: 'EXITO',
        categoryId: null,
      );

      expect(result.isRight(), isTrue);
      verifyNever(
        () => learning.learnMerchantCategory(
          merchantKey: any(named: 'merchantKey'),
          categoryId: any(named: 'categoryId'),
        ),
      );
    });
  });

  group('SuggestCategoryForMerchant', () {
    test('looks the normalized merchant up', () async {
      when(() => learning.suggestedCategoryFor(any()))
          .thenAnswer((_) async => const Right('category-1'));

      final result = await SuggestCategoryForMerchant(learning)('Éxito');

      expect(result.getOrElse((_) => null), 'category-1');
      verify(() => learning.suggestedCategoryFor('EXITO')).called(1);
    });

    test('suggests nothing for an unnamed merchant', () async {
      final result = await SuggestCategoryForMerchant(learning)(null);

      expect(result.getOrElse((_) => 'x'), isNull);
      verifyNever(() => learning.suggestedCategoryFor(any()));
    });
  });

  group('ForgetCaptureLearning', () {
    test('forgets one association by its normalized key', () async {
      when(() => learning.forgetMerchant(any()))
          .thenAnswer((_) async => const Right(unit));

      await ForgetCaptureLearning(learning)('Éxito Calle 80');

      verify(() => learning.forgetMerchant('EXITO CALLE 80')).called(1);
    });
  });

  group('DeleteAllCaptureData', () {
    test('wipes captures and learning, and nothing else', () async {
      when(repository.deleteAllCaptures)
          .thenAnswer((_) async => const Right(unit));
      when(learning.forgetAllLearning)
          .thenAnswer((_) async => const Right(unit));

      final result = await DeleteAllCaptureData(repository, learning)();

      expect(result.isRight(), isTrue);
      verify(repository.deleteAllCaptures).called(1);
      verify(learning.forgetAllLearning).called(1);
      verifyNever(
        () => repository.confirmCapture(
          captureId: any(named: 'captureId'),
          draft: any(named: 'draft'),
        ),
      );
    });

    test('does not wipe the learning when the captures could not be deleted',
        () async {
      when(repository.deleteAllCaptures)
          .thenAnswer((_) async => const Left(DatabaseFailure('busy')));

      final result = await DeleteAllCaptureData(repository, learning)();

      expect(result.isLeft(), isTrue);
      verifyNever(learning.forgetAllLearning);
    });
  });
}
