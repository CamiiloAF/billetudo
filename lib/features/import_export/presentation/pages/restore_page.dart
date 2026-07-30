import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/restore_cubit.dart';
import '../cubit/restore_state.dart';
import '../widgets/restore_body.dart';

/// HU-04 restore flow (`uUGXf`/`weAqZ`, `MjNwC`/`NY5o6`).
class RestorePage extends StatelessWidget {
  const RestorePage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<RestoreCubit, RestoreState>(
      builder: (context, state) {
        final cubit = context.read<RestoreCubit>();

        return PopScope(
          canPop: state.step != RestoreStep.running,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PageHeader(title: l10n.importExportRestoreTitle),
                  Expanded(
                    child: RestoreBody(state: state, cubit: cubit, onDone: onDone),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
