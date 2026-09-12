import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_state.dart';
import 'package:billetudo/features/capture/presentation/pages/notices_page.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

class MockNoticesCubit extends MockCubit<NoticesState>
    implements NoticesCubit {}

/// `Bk8zW` — the Avisos centre, end to end: its two empty states and the
/// captures section with a mixed queue (ordinary, grouped, possible
/// duplicate) both under and over the visible cap (`YliJD` block row).
void main() {
  late MockNoticesCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockNoticesCubit());

  Future<void> golden(
    WidgetTester tester,
    NoticesState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<NoticesCubit>.value(
        value: cubit,
        child: NoticesPage(
          onDispatchCapture: (_) {},
          onChooseIssuers: () {},
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/notices_page_$name.png'),
    );
  }

  CaptureReviewItem ordinaryItem(String id) => CaptureReviewItem(
        capture: buildPendingCapture(
          id: id,
          merchantRaw: 'TIENDA D1 SANTA ROSA',
          amountMinor: 5847000,
        ),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
      );

  CaptureReviewItem groupedItem(String id) => CaptureReviewItem(
        capture: buildPendingCapture(id: id, merchantRaw: null),
        accountName: 'Bancolombia *4417',
        issuerName: 'Bancolombia',
        group: const CaptureGroupView(
          merchantRaw: 'CAFETERIA LA ESPIGA',
          walletIssuerName: 'Google Wallet',
          bankIssuerName: 'Bancolombia',
        ),
      );

  CaptureReviewItem duplicateItem(String id) => CaptureReviewItem(
        capture: buildPendingCapture(id: id, amountMinor: 11525000),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
        duplicate: CaptureDuplicateView(
          transactionId: 'tx-1',
          amountMinor: 11525000,
          currency: 'COP',
          type: TransactionType.expense,
          date: DateTime(2026, 9, 1, 11, 9),
          accountMatches: true,
          title: 'Mercado de la semana',
          accountName: 'Cuenta Nu',
          categoryName: 'Mercado',
        ),
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('empty, todo al dia ($suffix)', (tester) async {
      await golden(
        tester,
        const NoticesState(status: NoticesStatus.ready, captures: []),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty without enabled issuers ($suffix)', (tester) async {
      await golden(
        tester,
        const NoticesState(
          status: NoticesStatus.ready,
          captures: [],
          hasEnabledIssuers: false,
        ),
        'empty_no_issuers_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('mixed queue under the cap, no block row ($suffix)',
        (tester) async {
      await golden(
        tester,
        NoticesState(
          status: NoticesStatus.ready,
          captures: [
            duplicateItem('capture-1'),
            groupedItem('capture-2'),
          ],
        ),
        'mixed_under_cap_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('queue over the cap shows the review-all block row ($suffix)',
        (tester) async {
      await golden(
        tester,
        NoticesState(
          status: NoticesStatus.ready,
          captures: [
            ordinaryItem('capture-1'),
            ordinaryItem('capture-2'),
            ordinaryItem('capture-3'),
            ordinaryItem('capture-4'),
            ordinaryItem('capture-5'),
          ],
        ),
        'over_cap_$suffix',
        brightness: brightness,
      );
    });
  }
}
