import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../cubit/archived_accounts_cubit.dart';
import '../cubit/archived_accounts_state.dart';
import '../widgets/accounts_error_view.dart';
import '../widgets/archived_account_row.dart';
import '../widgets/empty_state.dart';

/// "Cuentas archivadas" (`ft48Z`/`eAwin`, HU-07).
class ArchivedAccountsPage extends StatelessWidget {
  const ArchivedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsArchivedTitle),
        actions: const [
          // A real 44x44 spacer where the "+" sits elsewhere, so the title stays
          // centred. Excluded from semantics rather than painted over: an empty
          // focusable target is a phantom stop for a screen reader.
          ExcludeSemantics(child: SizedBox(width: 44, height: 44)),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ArchivedAccountsCubit, ArchivedAccountsState>(
          builder: (context, state) => switch (state.status) {
            ArchivedAccountsStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ArchivedAccountsStatus.failure => AccountsErrorView(
                onRetry: context.read<ArchivedAccountsCubit>().start,
              ),
            ArchivedAccountsStatus.ready when state.accounts.isEmpty =>
              // No CTA: archiving does not start from here.
              EmptyState(
                icon: LucideIcons.archive,
                message: l10n.accountsArchivedEmptyMessage,
              ),
            ArchivedAccountsStatus.ready => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.accounts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = state.accounts[index];
                  return ArchivedAccountRow(
                    entry: entry,
                    onUnarchive: () => context
                        .read<ArchivedAccountsCubit>()
                        .unarchive(entry.account.id),
                  );
                },
              ),
          },
        ),
      ),
    );
  }
}
