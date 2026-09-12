import 'package:equatable/equatable.dart';

/// The debt a scheduled payment is a cuota of (HU-03 cross-link), reduced to
/// just what the Pagos Programados detail needs to render its "Cuota de …"
/// card and deep-link back into the debt: the debt's id, its display name and
/// which way it points.
///
/// Deliberately NOT the Deudas `Debt` entity: keeping this a small
/// PP-owned value object means this feature's domain never depends on Deudas'.
/// [iOwe] mirrors `DebtDirection.iOwe` as a plain flag so the presentation can
/// pick the direction label ("Yo debo" / "Me deben") from the shared l10n
/// without importing the debt enum.
class ScheduledPaymentLinkedDebt extends Equatable {
  const ScheduledPaymentLinkedDebt({
    required this.id,
    required this.name,
    required this.iOwe,
    this.closedAt,
  });

  final String id;
  final String name;

  /// True when the user owes the debt (`DebtDirection.iOwe` → the cuota is an
  /// expense); false when the money is owed to the user (`owedToMe` → income).
  final bool iOwe;

  /// `Debts.closedAt`, mapped through unchanged: non-null once the debt was
  /// manually closed or completed (HU-07 in Deudas). Lets
  /// `ScheduledPaymentDetail.isActive` finish a linked cuota's template the
  /// moment its debt closes, without this feature depending on the `Debt`
  /// entity or writing anything back to `ScheduledPayments`.
  final DateTime? closedAt;

  bool get isClosed => closedAt != null;

  @override
  List<Object?> get props => [id, name, iOwe, closedAt];
}
