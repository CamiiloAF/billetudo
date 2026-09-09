import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/usecases/get_category.dart';
import '../../domain/entities/duplicate_candidate.dart';
import '../../domain/entities/issuer_catalog_entry.dart';
import '../../domain/entities/pending_capture.dart';
import '../../domain/usecases/discard_pending_capture.dart';
import '../../domain/usecases/find_duplicate_candidates.dart';
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
  ) : super(const NoticesState());

  final WatchPendingCaptures _watchPendingCaptures;
  final WatchIssuerCatalog _watchIssuerCatalog;
  final WatchAccounts _watchAccounts;
  final FindDuplicateCandidates _findDuplicateCandidates;
  final GetCategory _getCategory;
  final DiscardPendingCapture _discardPendingCapture;
  final RestorePendingCapture _restorePendingCapture;

  StreamSubscription<Result<List<PendingCapture>>>? _capturesSub;
  StreamSubscription<Result<List<IssuerCatalogEntry>>>? _issuersSub;
  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSub;

  List<PendingCapture>? _captures;
  Map<String, String> _accountNames = const <String, String>{};
  Map<String, String> _issuerNames = const <String, String>{};

  /// Resolved duplicate lookups, keyed by capture id. A key present with a
  /// `null` value means "already looked up, no duplicate" — without that
  /// distinction [_recompute] would re-query the same capture forever.
  final Map<String, CaptureDuplicateView?> _duplicates =
      <String, CaptureDuplicateView?>{};

  /// Captures whose duplicate lookup is in flight, so a second emission of
  /// the stream does not fire the same query twice.
  final Set<String> _duplicatesInFlight = <String>{};

  void start() {
    _capturesSub ??= _watchPendingCaptures().listen(_onCaptures);
    _issuersSub ??= _watchIssuerCatalog().listen(_onIssuers);
    _accountsSub ??= _watchAccounts().listen(_onAccounts);
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
  /// Emits with whatever duplicate lookups have already resolved and kicks
  /// off the missing ones; each resolution calls back here, and finds itself
  /// cached, so this terminates.
  void _recompute() {
    final captures = _captures;
    if (captures == null || isClosed) {
      return;
    }
    emit(
      state.copyWith(
        status: NoticesStatus.ready,
        captures: [
          for (final capture in captures)
            CaptureReviewItem(
              capture: capture,
              accountName: capture.suggestedAccountId == null
                  ? null
                  : _accountNames[capture.suggestedAccountId],
              issuerName: _issuerNames[capture.sourcePackage],
              duplicate: _duplicates[capture.id],
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

  /// Looks up whether [capture] may be repeating a movement the user already
  /// recorded (HU-07). Only `TransactionDuplicateCandidate` reaches the UI:
  /// a capture-against-capture match is a pairing the review flow handles on
  /// its own, and showing it as "posible duplicado" would ask the user to
  /// compare two things neither of which is money yet.
  Future<void> _resolveDuplicate(PendingCapture capture) async {
    _duplicatesInFlight.add(capture.id);
    final result = await _findDuplicateCandidates(capture);
    if (isClosed) {
      return;
    }
    CaptureDuplicateView? view;
    if (result case Right(value: final candidates)) {
      for (final candidate in candidates) {
        if (candidate is TransactionDuplicateCandidate) {
          view = await _viewFor(candidate);
          break;
        }
      }
    }
    if (isClosed) {
      return;
    }
    _duplicatesInFlight.remove(capture.id);
    _duplicates[capture.id] = view;
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
      // The note is what the user actually wrote; the category name is the
      // next best thing before falling back to a neutral label in the widget.
      title: transaction.note ?? categoryName,
      accountName: _accountNames[transaction.accountId],
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
    );
  }

  /// Reveals every capture behind the overflow row (`sCJCZ`). One-way: the
  /// cap only exists to protect the first paint, so re-collapsing a list the
  /// user asked to see would be arbitrary.
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
