import 'package:equatable/equatable.dart';

/// What kind of app an issuer is. Only used for presentation and for the
/// wallet/bank pairing rule of HU-07: when two captures of the same amount
/// arrive within minutes from different issuers, the [bank] one owns the
/// account hint (it knows the real card) and the [wallet] one usually carries
/// the better merchant name.
enum IssuerKind { bank, wallet }

/// One app of the curated issuer catalog (HU-02).
///
/// The catalog is **closed**: only apps shipped with the app are listenable.
/// Nothing is processed from a package that is not in this catalog AND
/// switched on, and the filter is applied by `packageName` **before** any
/// notification content is read.
class IssuerCatalogEntry extends Equatable {
  const IssuerCatalogEntry({
    required this.packageName,
    required this.displayName,
    required this.kind,
    this.enabled = false,
  });

  /// Android `packageName`, the only thing the filter matches on.
  final String packageName;

  /// Name shown to the user. Not localized: these are brand names.
  final String displayName;

  final IssuerKind kind;

  /// Off by default, always: the user opts each issuer in, one by one.
  final bool enabled;

  IssuerCatalogEntry copyWith({bool? enabled}) => IssuerCatalogEntry(
        packageName: packageName,
        displayName: displayName,
        kind: kind,
        enabled: enabled ?? this.enabled,
      );

  @override
  List<Object?> get props => [packageName, displayName, kind, enabled];
}
