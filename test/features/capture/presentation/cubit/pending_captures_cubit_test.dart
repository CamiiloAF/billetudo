import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_catalog_entry.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_issuer_catalog.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_pending_captures.dart';
import 'package:billetudo/features/capture/presentation/cubit/pending_captures_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../capture_mocks.dart';

class MockWatchPendingCaptures extends Mock implements WatchPendingCaptures {}

class MockWatchIssuerCatalog extends Mock implements WatchIssuerCatalog {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

void main() {
  late MockWatchPendingCaptures watchCaptures;
  late MockWatchIssuerCatalog watchIssuers;
  late MockWatchAccounts watchAccounts;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    watchCaptures = MockWatchPendingCaptures();
    watchIssuers = MockWatchIssuerCatalog();
    watchAccounts = MockWatchAccounts();

    when(() => watchIssuers()).thenAnswer(
      (_) => Stream.value(
        const Right<Failure, List<IssuerCatalogEntry>>([
          IssuerCatalogEntry(
            packageName: 'com.nu.production',
            displayName: 'Nu',
            kind: IssuerKind.bank,
            enabled: true,
          ),
        ]),
      ),
    );
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(
        Right<Failure, List<AccountWithBalance>>([
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-1', name: 'Cuenta Nu'),
            balanceMinor: 0,
          ),
        ]),
      ),
    );
  });

  PendingCapturesCubit build() =>
      PendingCapturesCubit(watchCaptures, watchIssuers, watchAccounts);

  void stubCaptures(List<PendingCapture> captures) {
    when(() => watchCaptures()).thenAnswer(
      (_) => Stream.value(Right<Failure, List<PendingCapture>>(captures)),
    );
  }

  test('shows only captures whose suggested account still exists', () async {
    stubCaptures([
      buildPendingCapture(id: 'kept', suggestedAccountId: 'acc-1'),
      buildPendingCapture(id: 'no-account'),
      buildPendingCapture(id: 'gone-account', suggestedAccountId: 'acc-404'),
    ]);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.items.map((item) => item.id), ['kept']);
    await cubit.close();
  });

  test('resolves the issuer brand for the rows it keeps', () async {
    stubCaptures([buildPendingCapture(suggestedAccountId: 'acc-1')]);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.items.single.issuerName, 'Nu');
    expect(cubit.state.items.single.accountName, 'Cuenta Nu');
    await cubit.close();
  });

  test('never resolves a duplicate: that decision belongs to the inbox',
      () async {
    stubCaptures([buildPendingCapture(suggestedAccountId: 'acc-1')]);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.items.single.hasDuplicate, isFalse);
    await cubit.close();
  });

  test('is empty when nothing is pending, so the block disappears', () async {
    stubCaptures(const []);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.isEmpty, isTrue);
    await cubit.close();
  });
}
