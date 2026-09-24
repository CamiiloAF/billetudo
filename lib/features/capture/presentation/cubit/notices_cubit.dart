import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/usecases/get_category.dart';
import '../../domain/entities/duplicate_candidate.dart';
import '../../domain/entities/issuer_catalog_entry.dart';
import '../../domain/entities/parsed_capture.dart';
import '../../domain/entities/pending_capture.dart';
import '../../domain/usecases/discard_pending_capture.dart';
import '../../domain/usecases/drain_native_captures.dart';
import '../../domain/usecases/find_duplicate_candidates.dart';
import '../../domain/usecases/ingest_parsed_captures.dart';
import '../../domain/usecases/restore_pending_capture.dart';
import '../../domain/usecases/watch_issuer_catalog.dart';
import '../../domain/usecases/watch_pending_captures.dart';
import 'capture_review_item.dart';
import 'notices_state.dart';

/// Orchestrates the Avisos centre (`Bk8zW`): the captures waiting for review
/// (HU-04/HU-05), each resolved into what its card has to show.
///
/// Talks only to use cases, never a repository or a DAO.
///
/// **Nothing here promotes a capture to money.** Discarding writes a status,
/// confirming does not happen in this cubit at all — the page routes the user
/// to the ordinary transaction form and `ConfirmPendingCapture` is what
/// creates the movement, through the exact same validation a manual one goes
/// through. There is deliberately no "confirmar todas": it would be N blind
/// confirmations.
@injectable
class NoticesCubit extends Cubit<NoticesState> {
  NoticesCubit(
    this._watchPendingCaptures,
    this._watchIssuerCatalog,
    this._watchAccounts,
    this._findDuplicateCandidates,
    this._getCategory,
    this._discardPendingCapture,
    this._restorePendingCapture,
    this._drainNativeCaptures,
    this._ingestParsedCaptures,
  ) : super(const NoticesState());

  final WatchPendingCaptures _watchPendingCaptures;
  final WatchIssuerCatalog _watchIssuerCatalog;
  final WatchAccounts _watchAccounts;
  final FindDuplicateCandidates _findDuplicateCandidates;
  final GetCategory _getCategory;
  final DiscardPendingCapture _discardPendingCapture;
  final RestorePendingCapture _restorePendingCapture;
  final DrainNativeCaptures _drainNativeCaptures;
  final IngestParsedCaptures _ingestParsedCaptures;

  StreamSubscription<Result<List<PendingCapture>>>? _capturesSub;
  StreamSubscription<Result<List<IssuerCatalogEntry>>>? _issuersSub;
  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSub;

  List<PendingCapture>? _captures;
  Map<String, String> _accountNames = const <String, String>{};
  Map<String, String> _issuerNames = const <String, String>{};
  Map<String, IssuerKind> _issuerKinds = const <String, IssuerKind>{};

  /// Resolved duplicate lookups, keyed by capture id. A key present with a
  /// `null` value means "already looked up, no duplicate" — without that
  /// distinction [_recompute] would re-query the same capture forever.
  final Map<String, CaptureDuplicateView?> _duplicates =
      <String, CaptureDuplicateView?>{};

  /// Resolved wallet/bank grouping candidates (HU-07, high confidence),
  /// keyed by capture id. Same `null`-means-"looked up, nothing" convention
  /// as [_duplicates].
  final Map<String, CaptureDuplicateCandidate?> _groupCandidates =
      <String, CaptureDuplicateCandidate?>{};

  /// Captures whose duplicate/grouping lookup is in flight, so a second
  /// emission of the stream does not fire the same query twice.
  final Set<String> _duplicatesInFlight = <String>{};

  void start() {
    unawaited(_ingestBufferedCaptures());
    _capturesSub ??= _watchPendingCaptures().listen(_onCaptures);
    _issuersSub ??= _watchIssuerCatalog().listen(_onIssuers);
    _accountsSub ??= _watchAccounts().listen(_onAccounts);
  }

  Future<void> _ingestBufferedCaptures() async {
    final drained = await _drainNativeCaptures();
    if (drained case Left()) {
      return;
    }
    final captures = drained.getOrElse((_) => const []);
    await _ingestParsedCaptures([
      for (final capture in captures)
        ParsedCapture(
          sourcePackage: capture.sourcePackage,
          sourceRuleId: capture.ruleId,
          postedAt: capture.postedAt,
          amountMinor: capture.amountMinor,
          currency: capture.currency,
          entryType: capture.entryType,
          merchantRaw: capture.merchantRaw,
          accountHint: capture.accountHint,
        ),
    ]);
  }

  void _onCaptures(Result<List<PendingCapture>> result) {
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(status: NoticesStatus.failure, failure: failure));
      case Right(value: final captures):
        _captures = captures;
        // Drop cached lookups of captures that left the inbox, so a long
        // session does not keep growing a map of ids nobody renders.
        final ids = captures.map((capture) => capture.id).toSet();
        _duplicates.removeWhere((id, _) => !ids.contains(id));
        _groupCandidates.removeWhere((id, _) => !ids.contains(id));
        _recompute();
    }
  }

  void _onIssuers(Result<List<IssuerCatalogEntry>> result) {
    if (isClosed) {
      return;
    }
    if (result case Right(value: final issuers)) {
      _issuerNames = {
        for (final issuer in issuers) issuer.packageName: issuer.displayName,
      };
      _issuerKinds = {
        for (final issuer in issuers) issuer.packageName: issuer.kind,
      };
      final hasEnabled = issuers.any((issuer) => issuer.enabled);
      emit(state.copyWith(hasEnabledIssuers: hasEnabled));
      _recompute();
    }
  }

  void _onAccounts(Result<List<AccountWithBalance>> result) {
    if (isClosed) {
      return;
    }
    if (result case Right(value: final accounts)) {
      _accountNames = {
        for (final entry in accounts) entry.account.id: entry.account.name,
      };
      _recompute();
    }
  }

  /// Rebuilds the rendered list from the latest emission of every stream.
  /// Emits with whatever duplicate/group lookups have already resolved and
  /// kicks off the missing ones; each resolution calls back here, and finds
  /// itself cached, so this terminates.
  void _recompute() {
    final captures = _captures;
    if (captures == null || isClosed) {
      return;
    }

    // Fold a wallet/bank pair into ONE rendered item (HU-07, high
    // confidence): the bank leg survives as the visible card — it is the one
    // that actually knows the account — and the wallet leg is dropped from
    // this list entirely. Neither row is touched in the database; this is
    // presentation-only, per capture.
    final hiddenGroupedIds = <String>{};
    final groupViews = <String, CaptureGroupView>{};
    for (final capture in captures) {
      if (groupViews.containsKey(capture.id) ||
          hiddenGroupedIds.contains(capture.id)) {
        continue;
      }
      final candidate = _groupCandidates[capture.id];
      if (candidate == null) {
        continue;
      }
      final other = candidate.capture;
      if (!captures.any((c) => c.id == other.id)) {
        continue;
      }
      final myKind = _issuerKinds[capture.sourcePackage];
      final otherKind = _issuerKinds[other.sourcePackage];
      if (myKind == null || otherKind == null || myKind == otherKind) {
        continue;
      }
      final bank = myKind == IssuerKind.bank ? capture : other;
      final wallet = myKind == IssuerKind.wallet ? capture : other;
      hiddenGroupedIds.add(wallet.id);
      groupViews[bank.id] = CaptureGroupView(
        merchantRaw: wallet.merchantRaw,
        walletIssuerName: _issuerNames[wallet.sourcePackage],
        bankIssuerName: _issuerNames[bank.sourcePackage],
      );
    }

    emit(
      state.copyWith(
        status: NoticesStatus.ready,
        captures: [
          for (final capture in captures)
            if (!hiddenGroupedIds.contains(capture.id))
              CaptureReviewItem(
                capture: capture,
                accountName: capture.suggestedAccountId == null
                    ? null
                    : _accountNames[capture.suggestedAccountId],
                issuerName: _issuerNames[capture.sourcePackage],
                duplicate: _duplicates[capture.id],
                group: groupViews[capture.id],
              ),
        ],
      ),
    );
    for (final capture in captures) {
      if (!_duplicates.containsKey(capture.id) &&
          !_duplicatesInFlight.contains(capture.id)) {
        unawaited(_resolveDuplicate(capture));
      }
    }
  }

  /// Looks up whether [capture] may be repeating something else in the app
  /// (HU-07): a `TransactionDuplicateCandidate` (possible, against something
  /// the user typed by hand) becomes the "posible duplicado" card, and a
  /// high-confidence `CaptureDuplicateCandidate` from a *different* issuer
  /// kind (the wallet/bank pairing, never the same-issuer-twice case, which
  /// this branch does not group) feeds [_recompute]'s fold above.
  Future<void> _resolveDuplicate(PendingCapture capture) async {
    _duplicatesInFlight.add(capture.id);
    final result = await _findDuplicateCandidates(capture);
    if (isClosed) {
      return;
    }
    CaptureDuplicateView? view;
    CaptureDuplicateCandidate? group;
    if (result case Right(value: final candidates)) {
      for (final candidate in candidates) {
        switch (candidate) {
          case TransactionDuplicateCandidate():
            view ??= await _viewFor(candidate);
          case CaptureDuplicateCandidate(
              confidence: DuplicateConfidence.high,
              sameIssuer: false,
            ):
            group ??= candidate;
          case CaptureDuplicateCandidate():
            break;
        }
      }
    }
    if (isClosed) {
      return;
    }
    _duplicatesInFlight.remove(capture.id);
    _duplicates[capture.id] = view;
    _groupCandidates[capture.id] = group;
    _recompute();
  }

  Future<CaptureDuplicateView> _viewFor(
    TransactionDuplicateCandidate candidate,
  ) async {
    final transaction = candidate.transaction;
    final categoryId = transaction.categoryId;
    String? categoryName;
    String? categoryIcon;
    String? categoryColor;
    if (categoryId != null) {
      final result = await _getCategory(categoryId);
      if (result case Right(value: final category)) {
        categoryName = category.name;
        categoryIcon = category.icon;
        categoryColor = category.color;
      }
    }
    return CaptureDuplicateView(
      transactionId: transaction.id,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      type: transaction.type,
      date: transaction.date,
      accountMatches: candidate.accountMatches,
      // The note is what the user actually wrote; a neutral label is the
      // widget's job when there is none. The category has its own slot now
      // (HU-07) and is never folded into the title.
      title: transaction.note,
      accountName: _accountNames[transaction.accountId],
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
    );
  }

  /// Reveals every capture behind the block-action row
  /// (`CaptureBlockActionRow`, "Revisar las N capturas"): the guided,
  /// one-by-one review, never a bulk confirmation. One-way: the cap only
  /// exists to protect the first paint, so re-collapsing a list the user
  /// asked to see would be arbitrary.
  void expandCaptures() => emit(state.copyWith(capturesExpanded: true));

  /// Throws a capture away (HU-05). Creates no transaction and touches no
  /// balance. [duplicateOfTransactionId] carries the transaction the user
  /// pointed at when answering "Es la misma" — the user's answer being
  /// written down, never the app deciding on its own.
  Future<void> discard(
    String captureId, {
    String? duplicateOfTransactionId,
  }) async {
    final result = await _discardPendingCapture(
      captureId,
      duplicateOfTransactionId: duplicateOfTransactionId,
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(failure: failure));
      case Right():
        emit(state.copyWith(discardedId: captureId));
    }
  }

  Future<void> undoDiscard() async {
    final captureId = state.discardedId;
    if (captureId == null) {
      return;
    }
    emit(state.copyWith(clearDiscardedId: true));
    final result = await _restorePendingCapture(captureId);
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }

  /// Acknowledges the undo affordance was shown, so the same snackbar is not
  /// replayed on the next unrelated rebuild.
  void discardNotified() => emit(state.copyWith(clearDiscardedId: true));

  @override
  Future<void> close() async {
    await _capturesSub?.cancel();
    await _issuersSub?.cancel();
    await _accountsSub?.cancel();
    return super.close();
  }
}
