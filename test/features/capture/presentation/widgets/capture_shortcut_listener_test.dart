import 'package:billetudo/features/capture/domain/entities/capture_shortcut.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_shortcut_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_shortcut_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_shortcut_listener.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCaptureShortcutCubit
    extends MockCubit<CaptureShortcutState>
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
}
