import 'package:equatable/equatable.dart';

/// A catalogued issuer as offered to the user in the "which apps do I listen
/// to" list (HU-02): the catalog entry crossed with what is actually installed
/// on this device and with what the user has switched on.
///
/// The catalog is closed: an app that is not in
/// `assets/capture/issuer_rules.json` can never appear here, and therefore can
/// never be listened to.
class IssuerApp extends Equatable {
  const IssuerApp({
    required this.issuerId,
    required this.displayName,
    required this.packageName,
    required this.installed,
    required this.enabled,
  });

  final String issuerId;
  final String displayName;

  /// The installed package that matched the catalog entry.
  final String packageName;

  /// Whether an app of this issuer is installed on the device.
  final bool installed;

  /// Whether the user switched this issuer ON. **Off by default, always**: a
  /// granted system permission with no issuer enabled captures nothing.
  final bool enabled;

  @override
  List<Object?> get props =>
      <Object?>[issuerId, displayName, packageName, installed, enabled];
}
