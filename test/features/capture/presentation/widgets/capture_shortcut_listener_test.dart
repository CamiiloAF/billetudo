import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/capture/domain/entities/capture_shortcut.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_shortcut_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_shortcut_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_shortcut_listener.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCaptureShortcutCubit extends MockCubit<CaptureShortcutState>
    implements CaptureShortcutCubit {}

void main() {
  late MockCaptureShortcutCubit cubit;

  setUp(() => cubit = MockCaptureShortcutCubit());

  Future<List<String>> pump(
    WidgetTester tester, {
    required String currentLocation,
  }) async {
    final opened = <String>[];
    await tester.pumpWidget(
      BlocProvider<CaptureShortcutCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: CaptureShortcutListener(
            currentLocation: () => currentLocation,
            onOpenRoute: opened.add,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    return opened;
  }

  testWidgets('opens the capture form the shortcut points at', (tester) async {
    whenListen(
      cubit,
      Stream.value(
        const CaptureShortcutState(pending: CaptureShortcut.expense),
      ),
      initialState: const CaptureShortcutState(),
    );

    final opened = await pump(tester, currentLocation: '/');
    await tester.pump();

    expect(opened, ['/movimientos/nuevo?type=expense']);
    verify(() => cubit.consumed()).called(1);
  });

  testWidgets('leaves an in-progress form alone', (tester) async {
    whenListen(
      cubit,
      Stream.value(
        const CaptureShortcutState(pending: CaptureShortcut.expense),
      ),
      initialState: const CaptureShortcutState(),
    );

    final opened = await pump(
      tester,
      currentLocation: '/movimientos/nuevo?type=expense',
    );
    await tester.pump();

    expect(opened, isEmpty);
    // Still consumed, so the ignored tap is not replayed later.
    verify(() => cubit.consumed()).called(1);
  });

  // Voice never has a `GoRoute` of its own (`AppRoutes.pendingWidgetTargets`'
  // doc): it opens `VoiceCaptureSheet` over Home via
  // `AppRoutes.rootNavigatorContext`, which this widget test never builds a
  // real router for, so it reads `null` here — same as before the app's
  // router is mounted. That still exercises the navigation-to-Home decision
  // in `_openVoiceCapture` without needing a real `Navigator` to anchor the
  // sheet to.
  group('voice shortcut', () {
    testWidgets('navigates to Home first when elsewhere, then stops there',
        (tester) async {
      whenListen(
        cubit,
        Stream.value(
            const CaptureShortcutState(pending: CaptureShortcut.voice)),
        initialState: const CaptureShortcutState(),
      );

      final opened = await pump(tester, currentLocation: '/movimientos');
      await tester.pump();

      expect(opened, [AppRoutes.home]);
      verify(() => cubit.consumed()).called(1);
    });

    testWidgets('already on Home: never re-navigates', (tester) async {
      whenListen(
        cubit,
        Stream.value(
            const CaptureShortcutState(pending: CaptureShortcut.voice)),
        initialState: const CaptureShortcutState(),
      );

      final opened = await pump(tester, currentLocation: AppRoutes.home);
      await tester.pump();

      expect(opened, isEmpty);
      verify(() => cubit.consumed()).called(1);
    });

    testWidgets('leaves onboarding alone: no navigation at all',
        (tester) async {
      whenListen(
        cubit,
        Stream.value(
            const CaptureShortcutState(pending: CaptureShortcut.voice)),
        initialState: const CaptureShortcutState(),
      );

      final opened = await pump(
        tester,
        currentLocation: AppRoutes.onboardingAccount,
      );
      await tester.pump();

      expect(opened, isEmpty);
      // Still consumed, same rule as the manual-form shortcuts above: an
      // ignored shortcut is never replayed once onboarding finishes.
      verify(() => cubit.consumed()).called(1);
    });
  });
}
