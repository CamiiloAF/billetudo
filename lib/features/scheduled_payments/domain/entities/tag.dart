import 'package:equatable/equatable.dart';

/// A free-form tag, a complement to categories: a scheduled payment template
/// can carry several at once via the `ScheduledPaymentTags` N:N relation.
///
/// Pure domain entity: no Drift types. Deliberately duplicated from
/// `transactions/domain/entities/tag.dart` instead of imported: the `Tags`
/// table is shared infrastructure with no owning feature, and this project
/// does not share domain entities across features for that reason — each
/// consuming feature mirrors the shape it needs.
class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  /// UUID as text.
  final String id;

  final String name;

  /// One of the decorative palette tokens, never a raw hex.
  final String? color;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  @override
  List<Object?> get props => [id, name, color, createdAt, updatedAt];
}
