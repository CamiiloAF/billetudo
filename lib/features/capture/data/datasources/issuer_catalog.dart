import '../../domain/entities/issuer_catalog_entry.dart';

/// The curated, **closed** issuer catalog of the launch (HU-02): the only
/// apps whose notifications can ever be listened to.
///
/// Closed on purpose — "we only look at banks" is the defensible posture both
/// towards Google Play and towards the user. A bank outside this list is
/// handled by widening the catalog in a later release, never by letting the
/// user type a package name in.
///
/// **This list must stay in lockstep with `assets/capture/issuer_rules.json`,
/// which is the single source of truth for the catalog.** An issuer listed
/// here but missing from the asset is worse than one that is absent: the user
/// sees it, switches it on, and it captures nothing — forever, and silently.
/// That is exactly the "don't promise coverage the app cannot deliver" rule
/// the requirement makes non-negotiable.
///
/// Four issuers were removed on 2026-09-09 for that reason:
///  - **Bancolombia** does not push at all, only SMS. An SMS arrives as a
///    notification of the *messaging* app, so capturing it would mean
///    listening to the whole inbox and reading every sender — including
///    one-time codes — to decide what to keep. That breaks the HU-08 rule of
///    filtering by package *before* reading anything, and it is the single
///    likeliest cause of a Play rejection.
///  - **Davivienda, Daviplata and BBVA Colombia** have no parsing rules yet,
///    and neither their package names nor their notification formats have
///    been verified against a real device.
///
/// Widening the catalog means adding the rules to the asset first, validated
/// against real notification text, and only then adding the entry here.
// TODO(cami): derive this list from `issuer_rules.json` at load time so the
// two cannot drift. Today they are two sources of truth for one thing.
const List<IssuerCatalogEntry> launchIssuerCatalog = <IssuerCatalogEntry>[
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
    packageName: 'com.google.android.apps.walletnfcrel',
    displayName: 'Google Wallet',
    kind: IssuerKind.wallet,
  ),
];
