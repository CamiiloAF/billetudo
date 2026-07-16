import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/transaction_with_details.dart';

enum TransactionDetailStatus { loading, ready, failure }

/// State of HU-08's detail screen.
class TransactionDetailState extends Equatable {
  const TransactionDetailState({
    this.status = TransactionDetailStatus.loading,
    this.entry,
    this.failure,
    this.deletePrompt = false,
    this.deleted = false,
  });

  final TransactionDetailStatus status;
  final TransactionWithDetails? entry;
  final Failure? failure;

  /// Whether the delete confirmation sheet should be showing.
  final bool deletePrompt;

  /// Set once the delete is confirmed and persisted: the page navigates back
  /// on this, in the same emission that closes [deletePrompt] — never a
  /// second emit, or the sheet flashes open again on its way out.
  final bool deleted;

  TransactionDetailState copyWith({
    TransactionDetailStatus? status,
    TransactionWithDetails? entry,
    Failure? failure,
    bool? deletePrompt,
    bool? deleted,
  }) =>
      TransactionDetailState(
        status: status ?? this.status,
        entry: entry ?? this.entry,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
        deletePrompt: deletePrompt ?? this.deletePrompt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props => [status, entry, failure, deletePrompt, deleted];
}
