import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transactions/domain/entities/transaction_filter.dart';
import '../cubit/capture_review_item.dart';
import '../cubit/pending_captures_cubit.dart';
import '../cubit/pending_captures_state.dart';
import 'pending_captures_block.dart';

/// The movements list's first slot: the pinned block of pending captures
/// (`vNjim`), or nothing at all.
///
/// It reads its own cubit rather than `TransactionsListState.items` on
/// purpose. A capture is not a `Transaction`; putting one in that list would
/// hand it to the date grouping and to `transactionGroupTotalFor`, and it
/// would start adding up.
///
/// [filter] is honoured, but only where it can be honoured honestly:
///  * an **account** filter narrows the block to the accounts being looked
///    at, since every capture shown here already resolves to one;
///  * a **type** filter drops the captures whose type is excluded;
///  * a **search**, **category** or **tag** filter hides the block outright —
///    a capture has no note to match, no category and no tags, so leaving it
///    on screen would claim it matched a query it was never tested against.
///
/// The **date** filter is deliberately ignored: the block lives outside the
/// day groups precisely because these rows are not placed in time yet.
class PendingCapturesListSlot extends StatelessWidget {
  const PendingCapturesListSlot({
    required this.filter,
    required this.onTap,
    super.key,
  });

  final TransactionFilter filter;
  /// `null` hides the block: link mode picks an existing movement, and a
  /// capture is not one.
  final ValueChanged<CaptureReviewItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (onTap == null) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<PendingCapturesCubit, PendingCapturesState>(
      builder: (context, state) {
        if (filter.searchText.trim().isNotEmpty ||
            filter.categoryIds.isNotEmpty ||
            filter.tagIds.isNotEmpty) {
          return const SizedBox.shrink();
        }
        final items = [
          for (final item in state.items)
            if ((filter.accountIds.isEmpty ||
                    filter.accountIds
                        .contains(item.capture.suggestedAccountId)) &&
                (filter.types.isEmpty ||
                    filter.types.contains(item.capture.entryType)))
              item,
        ];
        return PendingCapturesBlock(items: items, onTap: onTap);
      },
    );
  }
}
