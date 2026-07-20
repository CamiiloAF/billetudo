import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_state.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_delete_account_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/golden_helpers.dart';

class MockDeleteAccountCubit extends MockCubit<DeleteAccountState>
    implements DeleteAccountCubit {}

/// HU-07 paso 1: the destructive confirm sheet (`j8ZdEx` / `QOJ74`,
/// `$expense` tone, `triangle-alert`) and its neutral in-place error variant
/// (`T1YkkA`, `wifi-off`, "No pudimos eliminar tu cuenta"). No loading golden:
/// the design deliberately did not draw an "Eliminando…" frame (auth.md), the
/// only loading affordance is the spinner swapped into the CTA at runtime.
void main() {
  late MockDeleteAccountCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockDeleteAccountCubit());

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
            onPressed: () => ConfirmDeleteAccountSheet.show(context, cubit),
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
      matchesGoldenFile('goldens/confirm_delete_account_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirm, destructive ($suffix)', (tester) async {
      await golden(
        tester,
        const DeleteAccountState(),
        'confirm_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const DeleteAccountState(status: DeleteAccountStatus.error),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
