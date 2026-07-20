import 'package:billetudo/features/auth/domain/entities/merge_summary.dart';
import 'package:billetudo/features/auth/presentation/cubit/merge_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/merge_state.dart';
import 'package:billetudo/features/auth/presentation/pages/merge_confirmation_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockMergeCubit extends MockCubit<MergeState> implements MergeCubit {}

/// "Tus datos están a salvo" (`vexqA` / `V5NA1`, HU-04): the post-sign-in
/// merge confirmation. Three renderable states — ready (stats card), loading
/// (centered spinner), and failure (`wifi-off` error).
void main() {
  late MockMergeCubit cubit;

  const summary = MergeSummary(
    accountsCount: 3,
    transactionsCount: 20,
    categoriesCount: 8,
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockMergeCubit());

  Future<void> golden(
    WidgetTester tester,
    MergeState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<MergeCubit>.value(
        value: cubit,
        child: MergeConfirmationPage(onDone: () {}),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(MergeConfirmationPage),
      matchesGoldenFile('goldens/merge_confirmation_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('ready, with merge summary ($suffix)', (tester) async {
      await golden(
        tester,
        const MergeState(status: MergeStatus.ready, summary: summary),
        'ready_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const MergeState(),
        'loading_$suffix',
        brightness: brightness,
        // Indeterminate spinner — never settles.
        settle: false,
      );
    });

    testWidgets('failure ($suffix)', (tester) async {
      await golden(
        tester,
        const MergeState(status: MergeStatus.failure),
        'failure_$suffix',
        brightness: brightness,
      );
    });
  }
}
