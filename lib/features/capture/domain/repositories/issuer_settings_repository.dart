import '../../../../core/error/result.dart';
import '../entities/issuer_catalog_entry.dart';

/// Contract for which issuer apps are listened to (HU-02).
///
/// The catalog itself is closed and shipped with the app; what this stores is
/// only the user's per-issuer switch, off by default. Turning an issuer off
/// stops it from producing new captures immediately; captures already in the
/// inbox stay there until the user dispatches them.
abstract class IssuerSettingsRepository {
  /// The whole curated catalog with each entry's switch resolved. Entries the
  /// user has never touched come back `enabled: false`.
  FutureResult<List<IssuerCatalogEntry>> getIssuerCatalog();

  /// Emits the catalog again on every change, so the settings screen and the
  /// empty state of the inbox never disagree about how many issuers are on.
  Stream<Result<List<IssuerCatalogEntry>>> watchIssuerCatalog();

  /// Ignores a [packageName] outside the catalog: enabling an arbitrary
  /// package would silently widen what the app listens to, which is exactly
  /// what the closed catalog exists to prevent.
  FutureResult<Unit> setIssuerEnabled({
    required String packageName,
    required bool enabled,
  });

  /// Turns every issuer off in one action, without the user having to revoke
  /// the system permission (HU-02, HU-09).
  FutureResult<Unit> disableAllIssuers();

  /// Points an issuer at one of the user's accounts, or clears the link with
  /// a null [accountId]. Ignores a package outside the catalog, same as
  /// [setIssuerEnabled].
  FutureResult<Unit> setIssuerAccount({
    required String packageName,
    required String? accountId,
  });

  /// The account linked to [packageName], or `null` when there is none.
  /// Read on every capture, so it is a direct lookup rather than a scan of
  /// the whole catalog.
  FutureResult<String?> accountIdForPackage(String packageName);
}
