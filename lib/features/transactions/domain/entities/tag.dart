import 'package:equatable/equatable.dart';

/// A free-form tag (HU-07), a complement to categories: a transaction can
/// carry several at once via the `TransactionTags` N:N relation.
///
/// Pure domain entity: no Drift types.
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

  /// Epoch millis, not a `DateTime` (schema v5) — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  @override
  List<Object?> get props => [id, name, color, createdAt, updatedAt];
}
