import '../../domain/entities/issuer_catalog_entry.dart';

/// The curated, **closed** issuer catalog of the launch (HU-02): the only
/// apps whose notifications can ever be listened to.
///
/// Closed on purpose — "we only look at banks" is the defensible posture both
/// towards Google Play and towards the user. A bank outside this list is
/// handled by widening the catalog in a later release, never by letting the
/// user type a package name in.
///
/// **Interim location.** The requirement puts the issuer rules in a single
/// `assets/capture/issuer_rules.json`, read by the Kotlin listener in
/// production and mirrored by a Dart engine for tests, so a rule can never
/// exist on one side only. That asset does not exist yet (the native parser
/// is a separate piece of work), so this list holds the identity half of the
/// catalog — package and display name, no parsing rules — until the asset
/// lands, at which point this must be derived from it instead of restated.
///
/// **Only four package names are confirmed** against real notifications on a
/// device: `co.com.bancolombia.personas.superapp`, `com.nu.production`,
/// `com.nequi.MobileApp` and `com.google.android.apps.walletnfcrel`. The rest
/// are still unverified, and the requirement flags confirming each app's real
/// `packageName` as a prerequisite for writing its parsing rules — a wrong
/// package name here silently listens to nothing, which is the failure mode
/// this comment exists to prevent.
const List<IssuerCatalogEntry> launchIssuerCatalog = <IssuerCatalogEntry>[
  IssuerCatalogEntry(
    packageName: 'co.com.bancolombia.personas.superapp',
    displayName: 'Bancolombia',
    kind: IssuerKind.bank,
  ),
  IssuerCatalogEntry(
    packageName: 'com.nu.production',
    displayName: 'Nu',
    kind: IssuerKind.bank,
  ),
  IssuerCatalogEntry(
    packageName: 'com.nequi.MobileApp',
    displayName: 'Nequi',
    kind: IssuerKind.wallet,
  ),
  IssuerCatalogEntry(
    packageName: 'com.davivienda.daviviendaapp',
    displayName: 'Davivienda',
    kind: IssuerKind.bank,
  ),
  IssuerCatalogEntry(
    packageName: 'com.davivienda.daviplataapp',
    displayName: 'Daviplata',
    kind: IssuerKind.wallet,
  ),
  IssuerCatalogEntry(
    packageName: 'com.bbva.nxt_col',
    displayName: 'BBVA Colombia',
    kind: IssuerKind.bank,
  ),
  IssuerCatalogEntry(
    packageName: 'com.google.android.apps.walletnfcrel',
    displayName: 'Google Wallet',
    kind: IssuerKind.wallet,
  ),
];
