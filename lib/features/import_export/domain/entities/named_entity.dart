import 'package:equatable/equatable.dart';

/// A minimal id+name pair, used to offer the user existing accounts,
/// categories or tags to match a CSV row against (HU-06, "resolución de
/// destinos"). Deliberately not the full `Account`/`Category`/`Tag` entity:
/// this feature never needs anything else about them.
class NamedEntity extends Equatable {
  const NamedEntity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
