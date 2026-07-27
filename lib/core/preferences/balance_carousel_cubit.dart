import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'balance_carousel_preference_datasource.dart';
import 'balance_carousel_state.dart';

/// Drives the Movimientos balance carousel (Mejora #2): its collapsed/expanded
/// state (persisted per-device via [BalanceCarouselPreferenceDatasource]) and
/// the active card index (in-memory only). Local-only, per-device — same
/// family as `ThemeModeCubit`, so it is registered `@lazySingleton`: the same
/// instance keeps the state alive across tab switches and re-entries into
/// Movimientos, and persists the collapse choice between sessions.
///
/// Only the collapse flag is written to disk. The active page survives just as
/// long as the singleton, which is enough for the FAB's account preselection
/// and for reopening the carousel on the last-swiped card.
@lazySingleton
class BalanceCarouselCubit extends Cubit<BalanceCarouselState> {
  BalanceCarouselCubit(this._datasource) : super(const BalanceCarouselState());

  final BalanceCarouselPreferenceDatasource _datasource;

  /// Loads the persisted collapse preference. Safe to call more than once
  /// (each entry into Movimientos): it only re-reads the stored value and
  /// never touches [BalanceCarouselState.currentPage].
  Future<void> load() async {
    final collapsed = await _datasource.readCollapsed();
    if (!isClosed) {
      emit(state.copyWith(collapsed: collapsed));
    }
  }

  /// Flips the carousel between collapsed and expanded, persisting the choice.
  Future<void> toggle() => _setCollapsed(!state.collapsed);

  Future<void> collapse() => _setCollapsed(true);

  Future<void> expand() => _setCollapsed(false);

  /// Records the card the user swiped to (the `PageView`'s `onPageChanged`).
  /// Not persisted.
  void pageChanged(int page) {
    if (state.currentPage != page) {
      emit(state.copyWith(currentPage: page));
    }
  }

  Future<void> _setCollapsed(bool collapsed) async {
    if (state.collapsed != collapsed) {
      emit(state.copyWith(collapsed: collapsed));
    }
    await _datasource.writeCollapsed(collapsed: collapsed);
  }
}
