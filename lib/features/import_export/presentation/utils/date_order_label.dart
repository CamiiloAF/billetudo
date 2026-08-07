import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/csv_dialect.dart';

/// Localized label for a [DateComponentOrder], shared by the mapping step
/// and its Automático/Manual widgets.
String dateOrderLabel(AppLocalizations l10n, DateComponentOrder order) => switch (order) {
      DateComponentOrder.isoYmd => l10n.importExportDateOrderYmd,
      DateComponentOrder.dayMonthYear => l10n.importExportDateOrderDmy,
      DateComponentOrder.monthDayYear => l10n.importExportDateOrderMdy,
    };
