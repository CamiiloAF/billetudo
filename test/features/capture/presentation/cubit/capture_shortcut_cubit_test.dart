import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/capture_shortcut.dart';
import 'package:billetudo/features/capture/domain/usecases/get_initial_capture_shortcut.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_capture_shortcuts.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_shortcut_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_shortcut_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetInitialCaptureShortcut extends Mock
    implements GetInitialCaptureShortcut {}

class MockWatchCaptureShortcuts extends Mock implements WatchCaptureShortcuts {}

void main() {
  late MockGetInitialCaptureShortcut getInitialCaptureShortcut;
  late MockWatchCaptureShortcuts watchCaptureShortcuts;
  late StreamController<CaptureShortcut> shortcuts;

  setUp(() {
    getInitialCaptureShortcut = MockGetInitialCaptureShortcut();
    watchCaptureShortcuts = MockWatchCaptureShortcuts();
    shortcuts = StreamController<CaptureShortcut>.broadcast();
    when(() => watchCaptureShortcuts()).thenAnswer((_) => shortcuts.stream);
  });

  tearDown(() => shortcuts.close());

  CaptureShortcutCubit build() => CaptureShortcutCubit(
        getInitialCaptureShortcut,
        watchCaptureShortcuts,
      );

  blocTest<CaptureShortcutCubit, CaptureShortcutState>(
    'queues the shortcut the app was launched with (cold start)',
    setUp: () => when(() => getInitialCaptureShortcut())
        .thenAnswer((_) async => const Right(CaptureShortcut.expense)),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [CaptureShortcutState(pending: CaptureShortcut.expense)],
  );

  blocTest<CaptureShortcutCubit, CaptureShortcutState>(
    'emits nothing on a normal launch',
    setUp: () => when(() => getInitialCaptureShortcut())
        .thenAnswer((_) async => const Right(null)),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const <CaptureShortcutState>[],
  );

  blocTest<CaptureShortcutCubit, CaptureShortcutState>(
    'a platform failure never surfaces: the app just opens as usual',
    setUp: () => when(() => getInitialCaptureShortcut()).thenAnswer(
      (_) async => const Left(UnexpectedFailure('no channel')),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const <CaptureShortcutState>[],
  );

  blocTest<CaptureShortcutCubit, CaptureShortcutState>(
    'queues a shortcut tapped while the app was already running',
    setUp: () => when(() => getInitialCaptureShortcut())
        .thenAnswer((_) async => const Right(null)),
    build: build,
    act: (cubit) async {
      await cubit.start();
      shortcuts.add(CaptureShortcut.voice);
    },
    expect: () => const [CaptureShortcutState(pending: CaptureShortcut.voice)],
  );

  blocTest<CaptureShortcutCubit, CaptureShortcutState>(
    'clears the queue once the app has navigated',
    setUp: () => when(() => getInitialCaptureShortcut())
        .thenAnswer((_) async => const Right(CaptureShortcut.income)),
    build: build,
    act: (cubit) async {
      await cubit.start();
      cubit.consumed();
    },
    expect: () => const [
      CaptureShortcutState(pending: CaptureShortcut.income),
      CaptureShortcutState(),
    ],
  );
}
