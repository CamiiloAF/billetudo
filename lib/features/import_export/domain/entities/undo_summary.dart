import 'package:equatable/equatable.dart';

/// What reverting an `ImportBatch` actually did (HU-08): every count the
/// confirmation sheet and the after-the-fact toast need, including *why* some
/// rows the batch created were kept instead of trashed (used outside it).
class UndoSummary extends Equatable {
  const UndoSummary({
    required this.transactionsTrashed,
    required this.accountsTrashed,
    required this.accountsKept,
    required this.categoriesTrashed,
    required this.categoriesKept,
    required this.tagsTrashed,
    required this.tagsKept,
    required this.manuallyEditedRowsTrashed,
  });

  final int transactionsTrashed;

  /// Accounts created by the batch that had no use outside it — trashed.
  final int accountsTrashed;

  /// Accounts created by the batch but used since by a row outside it —
  /// kept, never trashed (HU-08).
  final int accountsKept;

  final int categoriesTrashed;
  final int categoriesKept;
  final int tagsTrashed;
  final int tagsKept;

  /// Of the transactions trashed, how many had been edited by hand since the
  /// import — informational only, the confirmation sheet surfaces it before
  /// the user commits (HU-08).
  final int manuallyEditedRowsTrashed;

  @override
  List<Object?> get props => [
        transactionsTrashed,
        accountsTrashed,
        accountsKept,
        categoriesTrashed,
        categoriesKept,
        tagsTrashed,
        tagsKept,
        manuallyEditedRowsTrashed,
      ];
}
