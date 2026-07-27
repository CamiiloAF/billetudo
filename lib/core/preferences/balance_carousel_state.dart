import 'package:equatable/equatable.dart';

/// State of the Movimientos balance carousel (Mejora #2): whether it is
/// collapsed, plus which card is currently active.
///
/// Only [collapsed] is persisted per-device (see
/// `BalanceCarouselPreferenceDatasource`); [currentPage] is remembered for the
/// lifetime of the singleton cubit so the FAB can preselect the account of the
/// card the user last swiped to, and so the carousel reopens on that card after
/// being collapsed.
class BalanceCarouselState extends Equatable {
  const BalanceCarouselState({this.collapsed = false, this.currentPage = 0});

  /// `true` = the compact bar, `false` = the full carousel. Defaults to
  /// expanded until `load` resolves the stored value.
  final bool collapsed;

  /// Index of the active card in the shown-accounts list. Callers must clamp
  /// it against the current account count: the filter can shrink the set below
  /// this index.
  final int currentPage;

  BalanceCarouselState copyWith({bool? collapsed, int? currentPage}) =>
      BalanceCarouselState(
        collapsed: collapsed ?? this.collapsed,
        currentPage: currentPage ?? this.currentPage,
      );

  @override
  List<Object?> get props => [collapsed, currentPage];
}
