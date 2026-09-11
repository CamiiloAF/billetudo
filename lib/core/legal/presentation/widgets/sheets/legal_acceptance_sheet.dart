import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../di/injection.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/bottom_sheet_base.dart';
import '../../../domain/entities/legal_document_kind.dart';
import '../../cubit/legal_acceptance_cubit.dart';
import '../../cubit/legal_acceptance_state.dart';
import '../../pages/legal_document_viewer_page.dart';
import '../legal_doc_row.dart';

/// The just-in-time acceptance sheet shared by "Comenzar" and "Ya tengo
/// cuenta" (Pencil `TxoKJ`): same copy, same two documents, same single
/// "Acepto" button regardless of which entry point opened it — only the
/// caller decides what happens after acceptance.
class LegalAcceptanceSheet extends StatelessWidget {
  const LegalAcceptanceSheet({super.key});

  /// Shows the sheet unless this installation already accepted the
  /// manifest's current version, in which case it resolves to `true`
  /// immediately without any UI (`TxoKJ`'s context: "si ya fue aceptado, la
  /// hoja no vuelve a subir por ninguna de las dos rutas").
  ///
  /// Resolves to `true` only when "Acepto" was actually tapped (or
  /// acceptance was already on file); `false`/`null` otherwise ("Ahora no"
  /// or a dismiss).
  static Future<bool> showIfNeeded(BuildContext context) async {
    final cubit = getIt<LegalAcceptanceCubit>();
    await cubit.load();
    if (cubit.state.alreadyAccepted) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    final accepted = await BottomSheetBase.show<bool>(
      context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const LegalAcceptanceSheet(),
      ),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return BlocBuilder<LegalAcceptanceCubit, LegalAcceptanceState>(
      builder: (context, state) {
        final isAccepting = state.status == LegalAcceptanceStatus.accepting;
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
              child: Icon(
                LucideIcons.shieldCheck,
                color: colors.primaryOnSoft,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.legalAcceptanceSheetTitle,
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
              l10n.legalAcceptanceSheetMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            LegalDocRow(
              icon: LucideIcons.fileText,
              label: l10n.settingsTermsOfUse,
              onTap: () => LegalDocumentViewerPage.push(
                context,
                LegalDocumentKind.termsOfUse,
              ),
            ),
            const SizedBox(height: 8),
            LegalDocRow(
              icon: LucideIcons.shield,
              label: l10n.settingsPrivacyPolicy,
              onTap: () => LegalDocumentViewerPage.push(
                context,
                LegalDocumentKind.privacyPolicy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.legalAcceptanceSheetDeclaration,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isAccepting
                    ? null
                    : () async {
                        final accepted =
                            await context.read<LegalAcceptanceCubit>().accept();
                        if (context.mounted) {
                          Navigator.of(context).pop(accepted);
                        }
                      },
                icon: isAccepting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.check),
                label: Text(l10n.legalAcceptanceSheetAccept),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    isAccepting ? null : () => Navigator.of(context).pop(false),
                child: Text(l10n.legalAcceptanceSheetDecline),
              ),
            ),
          ],
        );
      },
    );
  }
}
