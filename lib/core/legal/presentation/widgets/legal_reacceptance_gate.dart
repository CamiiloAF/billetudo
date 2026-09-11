import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/injection.dart';
import '../../../widgets/bottom_sheet_base.dart';
import '../cubit/legal_reacceptance_cubit.dart';
import '../cubit/legal_reacceptance_state.dart';
import 'sheets/legal_reacceptance_sheet.dart';

/// Wraps the home shell: on its very first build after the app's first-launch
/// gate resolves, evaluates [LegalReacceptanceCubit.checkOnLaunch] and, if
/// needed, blocks all normal navigation behind [LegalReacceptanceSheet]
/// until the person accepts or exports their data
/// (`docs/legal/entrega-de-documentos-legales.md`).
///
/// [LegalReacceptanceCubit] is a `@lazySingleton` that only ever runs its
/// real check once per app launch, so mounting this gate more than once
/// (e.g. `HomeShellPage` rebuilding on branch switches) is harmless.
class LegalReacceptanceGate extends StatefulWidget {
  const LegalReacceptanceGate({required this.child, super.key});

  final Widget child;

  @override
  State<LegalReacceptanceGate> createState() => _LegalReacceptanceGateState();
}

class _LegalReacceptanceGateState extends State<LegalReacceptanceGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndMaybeShow());
  }

  Future<void> _checkAndMaybeShow() async {
    final cubit = getIt<LegalReacceptanceCubit>();
    await cubit.checkOnLaunch();
    if (!cubit.state.isVisible || !mounted) {
      return;
    }
    await BottomSheetBase.show<void>(
      context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocListener<LegalReacceptanceCubit, LegalReacceptanceState>(
          listener: (context, state) {
            if (!state.isVisible) {
              Navigator.of(context).pop();
            }
          },
          child: const LegalReacceptanceSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
