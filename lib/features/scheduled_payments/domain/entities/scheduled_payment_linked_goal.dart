import 'package:equatable/equatable.dart';

/// The goal a scheduled payment is a recurring contribution of (HU-16
/// cross-link), reduced to just what the Pagos Programados detail needs to
/// render its "Meta Enlazada" card and deep-link back into the goal: the
/// goal's id and its display name.
///
/// Deliberately NOT the Metas `Goal` entity: keeping this a small PP-owned
/// value object means this feature's domain never depends on Metas', same
/// precedent as `ScheduledPaymentLinkedDebt` for the debt cross-link.
class ScheduledPaymentLinkedGoal extends Equatable {
  const ScheduledPaymentLinkedGoal({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
