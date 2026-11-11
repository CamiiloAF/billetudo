import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/capture_background_cubit.dart';
import '../cubit/capture_background_state.dart';
import '../cubit/capture_review_item.dart';
import '../cubit/notices_cubit.dart';
import '../cubit/notices_state.dart';
import '../utils/capture_presentation.dart';
import '../widgets/capture_background_link.dart';
import '../widgets/capture_degraded_card.dart';
import '../widgets/capture_degraded_empty_view.dart';
import '../widgets/captures_section.dart';
import '../widgets/sheets/capture_background_sheet.dart';

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
///
/// It also owns HU-09's degraded surfaces: when `CaptureBackgroundCubit` says
/// the configured capture may have stopped, the captures section gets a state
/// card above its rows (or its "Todo al día" empty state is replaced by the
/// contextual one). The permission/issuer states keep their precedence: the
/// cubit only reports attention when both hold, and without attention the
/// screen is exactly what it was before.
class NoticesPage extends StatefulWidget {
  const NoticesPage({
    required this.onDispatchCapture,
    required this.onChooseIssuers,
    this.onOpenCaptureSetup,
    this.captureSupported,
    super.key,
  });

  /// Opens the ordinary transaction form pre-filled from the capture. The
  /// router supplies it: this page never builds a confirmation surface of
  /// its own, and a capture becomes a movement only through the same form
  /// and the same validation as a manual one.
  final ValueChanged<CaptureReviewItem> onDispatchCapture;
  final bool? captureSupported;

  /// Opens the issuer catalog (HU-02) from the "sin emisores" empty state.
  final VoidCallback onChooseIssuers;

  /// Opens the permission/issuer flow from the permanent "Ajustes de captura
  /// en segundo plano" link at the bottom of the screen. Receives whether the
  /// notification permission is already granted so the router can send the
  /// user to the missing step. `null` in tests that do not exercise the link.
  final ValueChanged<bool>? onOpenCaptureSetup;

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Every return to foreground re-reads the real capture state (HU-09): the
  /// user may have granted the battery exemption or revoked the notification
  /// access from Android Settings while this screen sat behind them. It is the
  /// same reasoning `CaptureIssuersPage` uses.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<CaptureBackgroundCubit>().refresh());
    }
  }

  void _openBackgroundSheet() =>
      unawaited(CaptureBackgroundSheet.show(context));

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
              child:
                  BlocBuilder<CaptureBackgroundCubit, CaptureBackgroundState>(
                builder: (context, background) =>
                    BlocConsumer<NoticesCubit, NoticesState>(
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
                          // Flutter 3.38 changed the default: a SnackBar with
                          // an action is now `persist: true`, so without this
                          // the undo snackbar never hides on its own. Every
                          // other action snackbar in the app already sets it
                          // (Home, Transactions, Presupuestos, Metas, etc.).
                          persist: false,
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
                        onChooseIssuers: widget.onChooseIssuers,
                        captureSupported: widget.captureSupported ??
                            defaultTargetPlatform == TargetPlatform.android,
                        showsDegraded: background.showsAttention,
                        onReviewCapture: _openBackgroundSheet,
                      );
                    }
                    return NoticesContentView(
                      state: state,
                      onDispatchCapture: widget.onDispatchCapture,
                      showsDegraded: background.showsAttention,
                      lastCaptureAt: background.lastCaptureAt,
                      onReviewCapture: _openBackgroundSheet,
                    );
                  },
                ),
              ),
            ),
            // HU-09's permanent door: a brand-new user who only granted the
            // permission and picked issuers would otherwise never see that two
            // system settings also matter.
            CaptureBackgroundLink(
              onOpenSetup: (bool permissionGranted) =>
                  widget.onOpenCaptureSetup?.call(permissionGranted),
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
///
/// A third state is HU-09's: when capture is configured but may have stopped,
/// "Todo al día" would be a promise the app cannot keep, so it is replaced by
/// [CaptureDegradedEmptyView]. The permission and issuer states still win, in
/// that order.
class NoticesEmptyView extends StatelessWidget {
  const NoticesEmptyView({
    required this.state,
    required this.onChooseIssuers,
    required this.captureSupported,
    required this.showsDegraded,
    required this.onReviewCapture,
    super.key,
  });

  final NoticesState state;
  final VoidCallback onChooseIssuers;
  final bool captureSupported;

  /// HU-09: draw the contextual degraded empty state instead of "Todo al día".
  final bool showsDegraded;

  /// Opens the background-capture sheet.
  final VoidCallback onReviewCapture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: !captureSupported
            ? EmptyState(
                icon: LucideIcons.checkCheck,
                iconColor: colors.mint,
                iconBackground: colors.mintSoft,
                message: l10n.captureNoticesEmptyTitle,
                description: l10n.captureNoticesEmptyDescription,
              )
            : state.isEmptyWithoutIssuers
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
                : showsDegraded
                    ? CaptureDegradedEmptyView(onReview: onReviewCapture)
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
    required this.showsDegraded,
    required this.lastCaptureAt,
    required this.onReviewCapture,
    super.key,
  });

  final NoticesState state;
  final ValueChanged<CaptureReviewItem> onDispatchCapture;

  /// HU-09: render the degraded card and the "última captura" footer.
  final bool showsDegraded;

  /// When the listener last produced a capture, for the degraded footer.
  final DateTime? lastCaptureAt;

  /// Opens the background-capture sheet.
  final VoidCallback onReviewCapture;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NoticesCubit>();
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
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
            // Same flow as the duplicate card's "Es la misma", without a
            // compared transaction to record: `DiscardPendingCapture` only
            // moves the row to `discarded`, so the page's undo snackbar
            // restores it for as long as the window lasts.
            onDiscard: (item) => cubit.discard(item.id),
            onDiscardDuplicate: (item) => cubit.discard(
              item.id,
              duplicateOfTransactionId: item.duplicate?.transactionId,
            ),
            onExpand: cubit.expandCaptures,
            // The state card sits above the rows, right under the section's
            // caption (`VW54R`), and the footer closes the section with when
            // the last capture arrived.
            alert: showsDegraded
                ? CaptureDegradedCard(
                    onReview: onReviewCapture,
                    onSnooze: () => unawaited(
                        context.read<CaptureBackgroundCubit>().snooze()),
                  )
                : null,
            footer: showsDegraded
                ? Text(
                    captureBackgroundLastCaptureLabel(
                      l10n,
                      lastCaptureAt,
                      localeName:
                          Localizations.localeOf(context).toLanguageTag(),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
