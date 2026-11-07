import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_state.dart';
import 'package:billetudo/features/capture/presentation/pages/notices_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

class MockNoticesCubit extends MockCubit<NoticesState>
    implements NoticesCubit {}

/// HU-05 on the Avisos centre: an ordinary capture can be thrown away from its
/// card, with the same undoable flow the duplicate card's "Es la misma" uses —
/// and the discard button must never dispatch the capture to the form.
void main() {
  late MockNoticesCubit cubit;

  setUp(() {
    cubit = MockNoticesCubit();
    when(() => cubit.discard(any())).thenAnswer((_) async {});
  });

  CaptureReviewItem item(String id) => CaptureReviewItem(
        capture: buildPendingCapture(id: id, merchantRaw: 'TIENDA D1'),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
      );

  Future<void> pumpPage(
    WidgetTester tester, {
    required ValueChanged<CaptureReviewItem> onDispatchCapture,
  }) async {
    when(() => cubit.state).thenReturn(
      NoticesState(
        status: NoticesStatus.ready,
        captures: [item('capture-1')],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<NoticesCubit>.value(
          value: cubit,
          child: NoticesPage(
            onDispatchCapture: onDispatchCapture,
            onChooseIssuers: () {},
            captureSupported: true,
          ),
        ),
      ),
    );
  }

  testWidgets('discarding from the card goes to the cubit, not to the form',
      (tester) async {
    var dispatched = 0;
    await pumpPage(tester, onDispatchCapture: (_) => dispatched++);

    await tester.tap(find.byTooltip('Descartar captura'));
    await tester.pump();

    verify(() => cubit.discard('capture-1')).called(1);
    expect(dispatched, 0);
  });

  testWidgets('the card itself still dispatches the capture to the form',
      (tester) async {
    final dispatched = <CaptureReviewItem>[];
    await pumpPage(tester, onDispatchCapture: dispatched.add);

    // Tap the card body, away from the trailing discard button.
    await tester.tap(find.text('TIENDA D1'));
    await tester.pump();

    expect(dispatched.single.capture.id, 'capture-1');
    verifyNever(() => cubit.discard(any()));
  });
}
