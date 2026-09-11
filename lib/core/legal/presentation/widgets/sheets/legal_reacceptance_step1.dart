import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../domain/entities/legal_document_kind.dart';
import '../../cubit/legal_reacceptance_cubit.dart';
import '../../cubit/legal_reacceptance_state.dart';
import '../../pages/legal_document_viewer_page.dart';
import '../legal_doc_row.dart';

/// Step 1 of the re-acceptance sheet (Pencil `JHwhG` — both documents
/// changed — and `X2781z` — only one did, singular copy).
class LegalReacceptanceStep1 extends StatelessWidget {
  const LegalReacceptanceStep1({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<LegalReacceptanceCubit>();
    final state = context.watch<LegalReacceptanceCubit>().state;
    final changedKinds = state.changedDocuments.map((doc) => doc.kind).toSet();
    final bothChanged = changedKinds.length > 1;
    final isAccepting = state.status == LegalReacceptanceStatus.accepting;

    final String title;
    final String message;
    final String acceptLabel;
    final IconData icon;
    if (bothChanged) {
      title = l10n.legalReacceptanceBothTitle;
      message = l10n.legalReacceptanceBothMessage;
      acceptLabel = l10n.legalReacceptanceBothAccept;
      icon = LucideIcons.fileText;
    } else if (changedKinds.contains(LegalDocumentKind.termsOfUse)) {
      title = l10n.legalReacceptanceSingleTermsTitle;
      message = l10n.legalReacceptanceSingleTermsMessage;
      acceptLabel = l10n.legalReacceptanceSingleTermsAccept;
      icon = LucideIcons.fileText;
    } else {
      title = l10n.legalReacceptanceSinglePrivacyTitle;
      message = l10n.legalReacceptanceSinglePrivacyMessage;
      acceptLabel = l10n.legalReacceptanceSinglePrivacyAccept;
      icon = LucideIcons.shield;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, color: colors.primaryOnSoft, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 16),
        // Fixed order (Terms -> Privacy) to match Pencil's `vEgX4`/`SjOTr`
        // component tree, independent of LegalDocumentKind's enum order.
        for (final kind in const [
          LegalDocumentKind.termsOfUse,
          LegalDocumentKind.privacyPolicy,
        ])
          if (changedKinds.contains(kind))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LegalDocRow(
                icon: kind == LegalDocumentKind.termsOfUse
                    ? LucideIcons.fileText
                    : LucideIcons.shield,
                label: kind == LegalDocumentKind.termsOfUse
                    ? l10n.settingsTermsOfUse
                    : l10n.settingsPrivacyPolicy,
                onTap: () => LegalDocumentViewerPage.push(context, kind),
              ),
            ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isAccepting ? null : cubit.accept,
            icon: isAccepting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check),
            label: Text(acceptLabel),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: InkWell(
            onTap: isAccepting ? null : cubit.goToDeclineConsequence,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Text(
                l10n.legalReacceptanceDecline,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.legalReacceptanceFootnote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
