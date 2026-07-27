import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_state.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_sign_out_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/golden_helpers.dart';

class MockSignOutSheetCubit extends MockCubit<SignOutSheetState>
    implements SignOutSheetCubit {}

/// "Cerrar sesión" (HU-06), the sheet this fidelity run exists for. Its three
/// designed business states, opened through a real trigger so the golden
/// includes the scrim, drag handle and `BottomSheetBase` chrome:
///
/// - opt-in off (`wlVUL` / `CWvdi`): neutral tone, data stays put.
/// - opt-in on, sync up to date (`c87DpD` / `Af1SN`): the majority case, no
///   warning — the destructive CTA and message, but nothing pending.
/// - opt-in on + unsynced changes (`dpxOS` / `WXI8Z`): adds the amber
///   `UnsyncedChangesWarning`. Pinned at 4 changes (the `.md`'s `>1` example)
///   so the ICU plural is deterministic, not tied to real queue data.
void main() {
  late MockSignOutSheetCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockSignOutSheetCubit());

  Future<void> golden(
    WidgetTester tester,
    SignOutSheetState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmSignOutSheet.show(context, cubit),
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
      matchesGoldenFile('goldens/confirm_sign_out_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('opt-in off ($suffix)', (tester) async {
      await golden(
        tester,
        const SignOutSheetState(),
        'optin_off_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('opt-in on, sync up to date ($suffix)', (tester) async {
      await golden(
        tester,
        const SignOutSheetState(deleteLocalData: true),
        'optin_on_synced_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('opt-in on, unsynced changes ($suffix)', (tester) async {
      await golden(
        tester,
        const SignOutSheetState(deleteLocalData: true, pendingUploadCount: 4),
        'optin_on_unsynced_$suffix',
        brightness: brightness,
      );
    });
  }
}
