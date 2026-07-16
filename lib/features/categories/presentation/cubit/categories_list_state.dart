import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_node.dart';

/// The four states the categories list renders (`bA51N`/`vH7RI`/`QZAKU`/
/// `oaBzm`). Like `AccountsListState`, `ready` splits into "with data" and
/// "empty" through [CategoriesListState.isEmpty].
enum CategoriesListStatus { loading, ready, failure }

class CategoriesListState extends Equatable {
  const CategoriesListState({
    this.status = CategoriesListStatus.loading,
    this.kind = CategoryKind.expense,
    this.nodes = const [],
    this.expandedRootIds = const {},
    this.failure,
  });

  final CategoriesListStatus status;

  /// Which segment of the Toggle (`hFu41`) is active. Categories never apply
  /// to transfers, so only income/expense exist here.
  final CategoryKind kind;

  /// Root -> subcategories, ordered by `sortOrder`, for the active [kind].
  final List<CategoryNode> nodes;

  /// Which root rows are expanded in the accordion. Purely a UI concern: the
  /// stream never carries it, so it survives re-emissions of the same data.
  final Set<String> expandedRootIds;

  final Failure? failure;

  bool get isLoading => status == CategoriesListStatus.loading;

  bool get isEmpty => status == CategoriesListStatus.ready && nodes.isEmpty;

  bool isExpanded(String rootId) => expandedRootIds.contains(rootId);

  CategoriesListState copyWith({
    CategoriesListStatus? status,
    CategoryKind? kind,
    List<CategoryNode>? nodes,
    Set<String>? expandedRootIds,
    Failure? failure,
  }) =>
      CategoriesListState(
        status: status ?? this.status,
        kind: kind ?? this.kind,
        nodes: nodes ?? this.nodes,
        expandedRootIds: expandedRootIds ?? this.expandedRootIds,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [status, kind, nodes, expandedRootIds, failure];
}
