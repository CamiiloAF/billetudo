import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_state.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/local_data_choice_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/golden_helpers.dart';

class MockDeleteAccountCubit extends MockCubit<DeleteAccountState>
    implements DeleteAccountCubit {}

/// HU-07 paso 2 (`K8SAG` / `jxqEb`): what to do with local data after the
/// cloud account is gone. No dark pattern — neither option is preselected, so
/// the real initial state (nothing chosen, CTA disabled) is a distinct golden
/// from each picked option.
///
/// - nothing selected: CTA disabled (`GamyH` / `Fqpgc` reference).
/// - keep selected / delete selected: the two post-selection states, CTA
///   enabled. The "decisión final" frame `K8SAG` shows "keep" preselected only
///   as a visual example of the picked state — captured here explicitly.
void main() {
  late MockDeleteAccountCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockDeleteAccountCubit());

  DeleteAccountState choiceState({LocalDataChoice? choice}) =>
      DeleteAccountState(step: DeleteAccountStep.localDataChoice, choice: choice);

  Future<void> golden(
    WidgetTester tester,
    DeleteAccountState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => LocalDataChoiceSheet.show(context, cubit),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/local_data_choice_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('nothing selected, CTA disabled ($suffix)', (tester) async {
      await golden(
        tester,
        choiceState(),
        'none_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('keep selected ($suffix)', (tester) async {
      await golden(
        tester,
        choiceState(choice: LocalDataChoice.keep),
        'keep_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('delete selected ($suffix)', (tester) async {
      await golden(
        tester,
        choiceState(choice: LocalDataChoice.delete),
        'delete_$suffix',
        brightness: brightness,
      );
    });
  }
}
