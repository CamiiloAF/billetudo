import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/restore_cubit.dart';
import '../../cubit/restore_state.dart';
import 'restore_sheet_step_view.dart';

/// Entry point for HU-04 restore (`uUGXf`/`weAqZ`, `NY5o6`/`MjNwC`,
/// `xdG9q`/`d9wzVg`, `a5XdP`/`TmHSC`): pick the `.billetudo.json` directly
/// with the OS's native file picker — no intermediate sheet, same pattern
/// already adopted for CSV import (`ImportFlowPage`) — then, only if a file
/// was actually chosen, drive the rest of the flow (summary/mode choice →
/// escalated "reemplazar todo" confirmation → progress → done/error) inside
/// a single modal sheet, all still owned by [RestoreCubit].
class RestoreSheet {
  const RestoreSheet._();

  /// Triggers the native file picker and, if a file was chosen, opens the
  /// restore sheet. Awaiting this resolves once the whole flow (including
  /// the sheet) is closed.
  static Future<void> show(BuildContext context) async {
    final cubit = getIt<RestoreCubit>()..reset();
    await cubit.pickFile();
    if (cubit.state.step == RestoreStep.pickFile) {
      // The user backed out of the native picker without choosing a file —
      // nothing to show, so this never opens a dead sheet.
      await cubit.close();
      return;
    }
    if (!context.mounted) {
      await cubit.close();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      // Not casually dismissible (matches `GuidedReviewSheet`'s precedent
      // for another mandatory, data-changing flow): the running step is
      // irreversible mid-flight (HU-04, "o queda completa, o no queda
      // nada") and every step already has its own explicit "Cancelar" /
      // "Listo" — a stray scrim tap or drag-down must never substitute for
      // those.
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocProvider<RestoreCubit>.value(
        value: cubit,
        child: const BottomSheetBase(child: RestoreSheetBody()),
      ),
    );
    await cubit.close();
  }
}

/// The sheet's content for the current [RestoreState] — routes to running,
/// error, summary/mode-choice, the escalated "Reemplazar todo" confirmation
/// or done. `RestoreStep.pickFile` never reaches this: `RestoreSheet.show`
/// only opens the sheet once a file was chosen and its header parsed.
class RestoreSheetBody extends StatelessWidget {
  const RestoreSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestoreCubit, RestoreState>(
      builder: (context, state) {
        final cubit = context.read<RestoreCubit>();
        return RestoreSheetStepView(state: state, cubit: cubit);
      },
    );
  }
}
