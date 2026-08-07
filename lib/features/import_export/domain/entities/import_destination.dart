import 'package:equatable/equatable.dart';

/// Where a name found in the CSV (account, root category or subcategory)
/// resolves to (HU-06 "resolución de destinos"): an existing row, or a new
/// one to create at confirm time. Never "drop the row" — HU-06 is explicit
/// that no row is ever lost for lack of a destination.
sealed class ImportDestination extends Equatable {
  const ImportDestination();
}

/// The name matched (or the user mapped it to) an existing row.
class ExistingImportDestination extends ImportDestination {
  const ExistingImportDestination(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// The name has no match; a new row will be created for it at confirm time.
/// [parentName] is only set for a subcategory being created under a root that
/// is itself part of this same import (existing or also new).
class NewImportDestination extends ImportDestination {
  const NewImportDestination(this.name, {this.parentName});

  final String name;
  final String? parentName;

  @override
  List<Object?> get props => [name, parentName];
}
