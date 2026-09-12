import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/usecases/get_category.dart';
import '../../domain/entities/issuer_catalog_entry.dart';
import '../../domain/entities/pending_capture.dart';
import '../../domain/usecases/watch_issuer_catalog.dart';
import '../../domain/usecases/watch_pending_captures.dart';
import 'capture_review_item.dart';
import 'pending_captures_state.dart';

/// Feeds the ghost block at the top of the movements list (HU-04).
///
/// A thin sibling of `NoticesCubit`: it deliberately does **not** look up
/// duplicate candidates, because the movements list offers no comparison
/// affordance — that decision belongs in the Avisos centre, where both
/// answers can be shown with equal weight.
///
/// Nothing it emits ever reaches a balance, a budget, a goal or a chart.
@injectable
class PendingCapturesCubit extends Cubit<PendingCapturesState> {
  PendingCapturesCubit(
    this._watchPendingCaptures,
    this._watchIssuerCatalog,
    this._watchAccounts,
    this._getCategory,
  ) : super(const PendingCapturesState());

  final WatchPendingCaptures _watchPendingCaptures;
  final WatchIssuerCatalog _watchIssuerCatalog;
  final WatchAccounts _watchAccounts;
  final GetCategory _getCategory;

  StreamSubscription<Result<List<PendingCapture>>>? _capturesSub;
  StreamSubscription<Result<List<IssuerCatalogEntry>>>? _issuersSub;
  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSub;

  List<PendingCapture> _captures = const <PendingCapture>[];
  Map<String, String> _accountNames = const <String, String>{};
  Map<String, String> _issuerNames = const <String, String>{};

  /// Resolved category names, keyed by category id. A key present with a
  /// `null` value means "already looked up, no name" (the category was
  /// deleted) — without that distinction the lookup below would retry
  /// forever.
  final Map<String, String?> _categoryNames = <String, String?>{};
  final Set<String> _categoryLookupsInFlight = <String>{};

  void start() {
    _capturesSub ??= _watchPendingCaptures().listen((result) {
      if (result case Right(value: final captures)) {
        _captures = captures;
        _recompute();
      }
    });
    _issuersSub ??= _watchIssuerCatalog().listen((result) {
      if (result case Right(value: final issuers)) {
        _issuerNames = {
          for (final issuer in issuers) issuer.packageName: issuer.displayName,
        };
        _recompute();
      }
    });
    _accountsSub ??= _watchAccounts().listen((result) {
      if (result case Right(value: final accounts)) {
        _accountNames = {
          for (final entry in accounts) entry.account.id: entry.account.name,
        };
        _recompute();
      }
    });
  }

  void _recompute() {
    if (isClosed) {
      return;
    }
    final items = <CaptureReviewItem>[];
    for (final capture in _captures) {
      final accountId = capture.suggestedAccountId;
      final accountName = accountId == null ? null : _accountNames[accountId];
      // A capture whose suggested account is gone (or was never resolved)
      // drops out of this list rather than showing up accountless next to
      // real movements. It stays in the Avisos centre.
      if (accountName == null) {
        continue;
      }
      final categoryId = capture.suggestedCategoryId;
      items.add(
        CaptureReviewItem(
          capture: capture,
          accountName: accountName,
          issuerName: _issuerNames[capture.sourcePackage],
          suggestedCategoryName:
              categoryId == null ? null : _categoryNames[categoryId],
        ),
      );
      if (categoryId != null &&
          !_categoryNames.containsKey(categoryId) &&
          !_categoryLookupsInFlight.contains(categoryId)) {
        unawaited(_resolveCategoryName(categoryId));
      }
    }
    emit(state.copyWith(items: items));
  }

  Future<void> _resolveCategoryName(String categoryId) async {
    _categoryLookupsInFlight.add(categoryId);
    final result = await _getCategory(categoryId);
    if (isClosed) {
      return;
    }
    _categoryLookupsInFlight.remove(categoryId);
    _categoryNames[categoryId] = switch (result) {
      Right(value: final category) => category.name,
      Left() => null,
    };
    _recompute();
  }

  @override
  Future<void> close() async {
    await _capturesSub?.cancel();
    await _issuersSub?.cancel();
    await _accountsSub?.cancel();
    return super.close();
  }
}
