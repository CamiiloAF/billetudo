import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/capture_review_item.dart';
import '../cubit/notices_cubit.dart';
import '../cubit/notices_state.dart';
import '../widgets/captures_section.dart';

/// `Bk8zW` — the Avisos centre behind Home's bell. A **full screen on its own
/// route**, not a bottom sheet: it replaces the `ComingSoonSheet` the bell
/// used to open.
///
/// Two sections, each drawn only if it has content: "Avisos" (scheduled
/// charges, goals reached — owned by `feat/local-notifications`, hence the
/// gap left for it below) and "Capturas por confirmar" (HU-04/HU-05). When
/// neither has content the screen shows one empty state instead of orphan
/// headers.
///
/// Notices come first and weigh more on purpose: a charge falling due has a
/// consequence, a capture waiting on review affects no number at all.
class NoticesPage extends StatelessWidget {
  const NoticesPage({
    required this.onDispatchCapture,
    required this.onChooseIssuers,
    super.key,
  });

  /// Opens the ordinary transaction form pre-filled from the capture. The
  /// router supplies it: this page never builds a confirmation surface of
  /// its own, and a capture becomes a movement only through the same form
  /// and the same validation as a manual one.
  final ValueChanged<CaptureReviewItem> onDispatchCapture;

  /// Opens the issuer catalog (HU-02) from the "sin emisores" empty state.
  final VoidCallback onChooseIssuers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Only the header is fixed; everything below scrolls.
            PageHeader(title: l10n.captureNoticesTitle),
            Expanded(
              child: BlocConsumer<NoticesCubit, NoticesState>(
                listenWhen: (previous, current) =>
                    previous.discardedId != current.discardedId,
                listener: (context, state) {
                  if (state.discardedId == null) {
                    return;
                  }
                  final cubit = context.read<NoticesCubit>();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(l10n.captureDiscardedMessage),
                        action: SnackBarAction(
                          label: l10n.transactionsUndoAction,
                          onPressed: cubit.undoDiscard,
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                },
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.isEmpty) {
                    return NoticesEmptyView(
                      state: state,
                      onChooseIssuers: onChooseIssuers,
                    );
                  }
                  return NoticesContentView(
                    state: state,
                    onDispatchCapture: onDispatchCapture,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `MEkB8` / `oaH1Q` — nothing to review.
///
/// Two empty states, not one: when the permission is granted but no issuer is
/// switched on, the captures section can never fill, so the screen explains
/// the cause and links to the catalog instead of saying "todo al día" and
/// leaving the user waiting forever. Neither uses alarm iconography — a
/// missing setting is not a failure — and "Todo al día" carries no CTA,
/// because inventing a button here would invent a task that does not exist.
class NoticesEmptyView extends StatelessWidget {
  const NoticesEmptyView({
    required this.state,
    required this.onChooseIssuers,
    super.key,
  });

  final NoticesState state;
  final VoidCallback onChooseIssuers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: state.isEmptyWithoutIssuers
            ? EmptyState(
                icon: LucideIcons.listChecks,
                iconColor: colors.primaryOnSoft,
                iconBackground: colors.primarySoft,
                message: l10n.captureNoIssuersTitle,
                description: l10n.captureNoIssuersDescription,
                ctaLabel: l10n.captureNoIssuersCta,
                ctaIcon: LucideIcons.listChecks,
                onCta: onChooseIssuers,
              )
            : EmptyState(
                icon: LucideIcons.checkCheck,
                iconColor: colors.mint,
                iconBackground: colors.mintSoft,
                message: l10n.captureEmptyTitle,
                description: l10n.captureEmptyDescription,
              ),
      ),
    );
  }
}

/// The scrollable body: the notices section (when that branch lands) followed
/// by the captures section, 18pt apart.
class NoticesContentView extends StatelessWidget {
  const NoticesContentView({
    required this.state,
    required this.onDispatchCapture,
    super.key,
  });

  final NoticesState state;
  final ValueChanged<CaptureReviewItem> onDispatchCapture;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NoticesCubit>();
    return ListView(
      // `ruuuN` [10,20,20,20] with both sections; `E91A7T` [4,20,28,20] with
      // captures alone — the tighter top exists to buy back the height the
      // notices section needs.
      padding: state.hasNotices
          ? const EdgeInsets.fromLTRB(20, 10, 20, 20)
          : const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        // Gap reserved for the "Avisos" section owned by
        // `feat/local-notifications`. It goes first and is followed by an
        // 18pt gap before the captures; nothing is drawn while it has no
        // content, so no header is orphaned here today.
        if (state.hasCaptures)
          CapturesSection(
            state: state,
            onDispatch: onDispatchCapture,
            onDiscardDuplicate: (item) => cubit.discard(
              item.id,
              duplicateOfTransactionId: item.duplicate?.transactionId,
            ),
            onExpand: cubit.expandCaptures,
          ),
      ],
    );
  }
}
