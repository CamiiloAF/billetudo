import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';
import '../widgets/export_form.dart';

/// HU-01/HU-02: choose what to export (transactions/accounts/categories),
/// optionally filtered (`zFLrC`/`h6ZQQw`/`calDR`), then hand the result to
/// the share sheet. The write itself — blocking progress and a write
/// failure — is `ExportRunSheet`, a modal opened by `ExportForm`'s CTA
/// (`Bottom Sheet Base` in `billetudo.pen`, not this page's chrome).
class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.importExportExportPageTitle),
            Expanded(
              child: BlocBuilder<ExportCubit, ExportState>(
                builder: (context, state) {
                  if (!state.hasAnyTransactions &&
                      !state.scope.includeAccounts &&
                      !state.scope.includeCategories) {
                    return EmptyState(
                      icon: LucideIcons.fileSpreadsheet,
                      message: l10n.importExportExportEmptyTitle,
                      description: l10n.importExportExportEmptyBody,
                      // Neutral, not `$primary` — this empty state has no
                      // CTA, and `$primary` reads as "the cloud" in this
                      // 100%-local feature.
                      iconColor: context.colors.textSecondary,
                      iconBackground: context.colors.muted,
                    );
                  }
                  return ExportForm(state: state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
