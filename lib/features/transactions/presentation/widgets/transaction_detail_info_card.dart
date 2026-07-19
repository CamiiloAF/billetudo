import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/widgets/info_row.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';

/// The `Info Card`: a `$surface` container of `InfoRow`s, HU-08's detail
/// screen. Field order depends on the transaction's type — Cuenta(s) ->
/// Categoría (if applicable) -> Fecha -> Nota -> Origen — separated by
/// `$border` dividers between rows (never after the last one).
class TransactionDetailInfoCard extends StatelessWidget {
  const TransactionDetailInfoCard({
    required this.entry,
    required this.locale,
    super.key,
  });

  final TransactionWithDetails entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final transaction = entry.transaction;
    final note = transaction.note;

    final rows = <InfoRow>[
      if (transaction.isTransfer) ...[
        InfoRow(
          label: l10n.transactionDetailAccountFromLabel,
          value: entry.accountName,
        ),
        InfoRow(
          label: l10n.transactionDetailAccountToLabel,
          value: entry.transferAccountName ?? '',
        ),
      ] else ...[
        InfoRow(
          label: l10n.transactionDetailAccountLabel,
          value: entry.accountName,
        ),
        InfoRow(
          label: l10n.transactionDetailCategoryLabel,
          value: entry.categoryName ?? '',
        ),
      ],
      InfoRow(
        label: l10n.transactionDetailDateLabel,
        value: _formatDate(transaction.date),
      ),
      InfoRow(
        label: l10n.transactionDetailNoteLabel,
        value: note == null || note.isEmpty ? l10n.transactionDetailNoNote : note,
      ),
      InfoRow(
        label: l10n.transactionDetailSourceLabel,
        value: _sourceLabel(l10n, transaction.source),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: colors.border),
              const SizedBox(height: 16),
            ],
            rows[i],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      DateFormat("d 'de' MMMM, y", locale).format(date);

  /// HU-08 criterion 10: a legible label for every `TransactionSource`, even
  /// the ones no capture flow can produce yet.
  String _sourceLabel(AppLocalizations l10n, TransactionSource source) =>
      switch (source) {
        TransactionSource.manual => l10n.transactionSourceManual,
        TransactionSource.voice => l10n.transactionSourceVoice,
        TransactionSource.ocr => l10n.transactionSourceOcr,
        TransactionSource.notification => l10n.transactionSourceNotification,
        TransactionSource.imported => l10n.transactionSourceImported,
        TransactionSource.scheduled => l10n.transactionSourceScheduled,
      };
}
