import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/privacy_note_strip.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../cubit/ai_report_cubit.dart';
import '../../cubit/ai_report_state.dart';
import '../ai_reason_grid.dart';
import '../ai_report_comment_field.dart';

/// "Reportar mensaje" (`billetudo.pen` `zV9g3`/`G6uAwV`): the sheet
/// `AiMessageCopyMenu`'s "Reportar" row opens.
///
/// [reportedText] is the assistant message being reported, verbatim — the
/// only conversation content this feature ever sends to a server (see
/// `AiReport`'s own doc for why that single exception is safe).
///
/// Structural rule from the `.md`: the sheet is split into a scrollable zone
/// (icon header + reason grid + comment) and a **fixed** zone (privacy note +
/// buttons) so the privacy disclaimer can never be scrolled past unseen
/// before "Enviar" becomes reachable — same shape already used elsewhere in
/// the app for a hero's autofocus CTA.
class AiReportSheet extends StatelessWidget {
  const AiReportSheet({
    required this.reportedText,
    this.conversationId,
    super.key,
  });

  final String reportedText;
  final String? conversationId;

  /// Resolves to `true` once the report was filed, `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String reportedText,
    String? conversationId,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => AiReportSheet(
          reportedText: reportedText,
          conversationId: conversationId,
        ),
      );

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt<AiReportCubit>(),
        child: AiReportSheetBody(
          reportedText: reportedText,
          conversationId: conversationId,
        ),
      );
}

class AiReportSheetBody extends StatefulWidget {
  const AiReportSheetBody({
    required this.reportedText,
    this.conversationId,
    super.key,
  });

  final String reportedText;
  final String? conversationId;

  @override
  State<AiReportSheetBody> createState() => _AiReportSheetBodyState();
}

class _AiReportSheetBodyState extends State<AiReportSheetBody> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) => context.read<AiReportCubit>().submit(
        reportedText: widget.reportedText,
        conversationId: widget.conversationId,
      );

  String _failureMessage(AppLocalizations l10n, Failure? failure) =>
      failure is AiFailure && failure.code == AiFailureCode.unauthenticated
          ? l10n.aiReportErrorUnauthenticated
          : l10n.aiReportErrorGeneric;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return BlocConsumer<AiReportCubit, AiReportState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AiReportStatus.submitted) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AiReportCubit>();
        final errorText = state.status == AiReportStatus.failure
            ? _failureMessage(l10n, state.failure)
            : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ZONA SCROLLEABLE: header + reason grid + comment.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // `Sheet Icon Header` (`XPjIZ`): this instance keeps its
                    // base message color (`$text-secondary`), not the
                    // `SheetMessage` widget's own default (`$text-primary`)
                    // used by confirmation sheets elsewhere.
                    SheetMessage(
                      icon: LucideIcons.flag,
                      iconColor: colors.primaryOnSoft,
                      iconBackground: colors.primarySoft,
                      title: l10n.aiReportSheetTitle,
                      message: l10n.aiReportSheetMessage,
                      messageColor: colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    AiReasonGrid(
                      selected: state.reason,
                      onSelected: cubit.reasonSelected,
                    ),
                    const SizedBox(height: 16),
                    AiReportCommentField(
                      label: l10n.aiReportCommentLabel,
                      hint: l10n.aiReportCommentHint,
                      controller: _commentController,
                      onChanged: cubit.commentChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ZONA FIJA: privacy note + buttons, never scrolls away.
            PrivacyNoteStrip(
              icon: LucideIcons.uploadCloud,
              text: l10n.aiReportPrivacyNote,
            ),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.expenseText),
              ),
            ],
            const SizedBox(height: 16),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              right: Opacity(
                opacity: state.canSubmit ? 1 : 0.4,
                child: FilledButton.icon(
                  onPressed: state.canSubmit ? () => _submit(context) : null,
                  icon: const Icon(LucideIcons.flag),
                  label: Text(l10n.aiReportSubmit),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
