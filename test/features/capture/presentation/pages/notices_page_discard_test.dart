import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_state.dart';
import 'package:billetudo/features/capture/presentation/pages/notices_page.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

class MockNoticesCubit extends MockCubit<NoticesState>
    implements NoticesCubit {}

/// HU-05 in the Avisos centre, final design (`IMs3M`/`bkNc1`): a capture is
/// discarded by swiping its card towards the start edge — the undoable
/// `DiscardPendingCapture` flow — and the swipe must never dispatch the
/// capture to the form.
void main() {
  late MockNoticesCubit cubit;
  late MockCaptureBackgroundCubit background;

  setUp(() {
    cubit = MockNoticesCubit();
    background = MockCaptureBackgroundCubit();
    when(() => background.state).thenReturn(
      const CaptureBackgroundState(isSupported: true, isLoading: false),
    );
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
    Stream<NoticesState>? stream,
  }) async {
    final NoticesState initial = NoticesState(
      status: NoticesStatus.ready,
      captures: [item('capture-1')],
    );
    if (stream != null) {
      whenListen(cubit, stream, initialState: initial);
    } else {
      when(() => cubit.state).thenReturn(initial);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<NoticesCubit>.value(value: cubit),
            BlocProvider<CaptureBackgroundCubit>.value(value: background),
          ],
          child: NoticesPage(
            onDispatchCapture: onDispatchCapture,
            onChooseIssuers: () {},
            captureSupported: true,
          ),
        ),
      ),
    );
  }

  testWidgets('swiping the card discards through the cubit, never dispatch',
      (tester) async {
    var dispatched = 0;
    await pumpPage(tester, onDispatchCapture: (_) => dispatched++);

    // The test viewport is 800 wide, so the card is ~760 wide and the 35%
    // threshold is ~266px: drag well past it.
    await tester.drag(
      find.byType(PendingCaptureCard),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    verify(() => cubit.discard('capture-1')).called(1);
    expect(dispatched, 0);
  });

  testWidgets('the undo snackbar dismisses itself after its duration',
      (tester) async {
    // Regression: Flutter 3.38 defaults `SnackBar.persist` to `true` when the
    // bar carries an action, so a missing `persist: false` leaves the undo
    // snackbar on screen forever. The Avisos centre must set it explicitly.
    final NoticesState initial = NoticesState(
      status: NoticesStatus.ready,
      captures: [item('capture-1')],
    );
    await pumpPage(
      tester,
      onDispatchCapture: (_) {},
      stream: Stream<NoticesState>.value(
        initial.copyWith(discardedId: 'capture-1'),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);

    // The auto-dismiss timer is armed only once the entrance animation has
    // completed (`ScaffoldMessengerState` schedules it in its next build), so
    // settle first and then let the 5s duration elapse. The bar has to be gone
    // without a tap.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the card itself still dispatches the capture to the form',
      (tester) async {
    final dispatched = <CaptureReviewItem>[];
    await pumpPage(tester, onDispatchCapture: dispatched.add);

    await tester.tap(find.text('TIENDA D1'));
    await tester.pump();

    expect(dispatched.single.capture.id, 'capture-1');
    verifyNever(() => cubit.discard(any()));
  });
}
