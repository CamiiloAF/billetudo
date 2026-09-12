import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/legal_reacceptance_cubit.dart';
import '../../cubit/legal_reacceptance_state.dart';
import 'legal_reacceptance_step1.dart';
import 'legal_reacceptance_step2.dart';

/// The mandatory re-acceptance sheet (Pencil `JHwhG`/`X2781z` step 1,
/// `f8KnrT` step 2), shown when [LegalReacceptanceCubit] finds
/// `acceptedVersion < currentVersion` AND the installed app satisfies
/// `minAppVersion`.
///
/// Blocking by design: no handle, no dismiss on scrim tap, no drag-to-close
/// — `LegalReacceptanceGate` opens it with `isDismissible`/`enableDrag`
/// both `false`. The only ways out are accepting (step 1) or exporting
/// (step 2).
class LegalReacceptanceSheet extends StatelessWidget {
  const LegalReacceptanceSheet({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LegalReacceptanceCubit, LegalReacceptanceState>(
        builder: (context, state) =>
            state.status == LegalReacceptanceStatus.step2
                ? const LegalReacceptanceStep2()
                : const LegalReacceptanceStep1(),
      );
}
