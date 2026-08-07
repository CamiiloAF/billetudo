import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../domain/entities/import_destination.dart';
import '../../domain/entities/import_entry_type.dart';
import '../../domain/entities/import_preview.dart';
import '../../domain/entities/import_preview_row.dart';
import '../../domain/entities/named_entity.dart';
import '../../domain/utils/text_normalizer.dart';
import '../widgets/privacy_note_strip.dart';
import '../widgets/unresolved_destination_row.dart';

/// One unresolved name found in the CSV (HU-06 "resolución de destinos").
class UnresolvedDestination {
  const UnresolvedDestination({
    required this.key,
    required this.name,
    required this.icon,
    required this.kind,
    this.parentRootId,
    this.isExpense = true,
  });

  final String key;
  final String name;
  final IconData icon;
  final DestinationKind kind;

  /// Set only for subcategories whose root already resolved to an existing
  /// category — needed to fetch that root's existing subcategories.
  final String? parentRootId;

  /// Only meaningful for [DestinationKind.category]/[DestinationKind.subcategory]:
  /// which category tree to offer in the "mapear a existente" picker
  /// (`CategorySelectSheet`). Derived from the row's own [ImportEntryType]
  /// where the destination was first found; defaults to `true` (expense) for
  /// rows without a resolved type yet.
  final bool isExpense;
}

enum DestinationKind { account, category, subcategory, tag }

/// HU-06 destinations step (`kYBYa`/`u8TSNH`, chrome "3/4"): every CSV name
/// with no automatic match, resolved to "crear nueva" (default) or "mapear a
/// existente".
class ImportDestinationsStep extends StatelessWidget {
  const ImportDestinationsStep({
    required this.preview,
    required this.accountOverrides,
    required this.categoryOverrides,
    required this.subcategoryOverrides,
    required this.tagOverrides,
    required this.onAccountOverride,
    required this.onCategoryOverride,
    required this.onSubcategoryOverride,
    required this.onTagOverride,
    required this.loadExistingAccounts,
    required this.loadExistingRootCategories,
    required this.loadExistingSubcategories,
    required this.loadExistingTags,
    required this.onConfirm,
    this.onReviewMapping,
    super.key,
  });

  final ImportPreview preview;
  final Map<String, ImportDestination> accountOverrides;
  final Map<String, ImportDestination> categoryOverrides;
  final Map<String, ImportDestination> subcategoryOverrides;
  final Map<String, ImportDestination> tagOverrides;
  final void Function(String key, ImportDestination destination) onAccountOverride;
  final void Function(String key, ImportDestination destination) onCategoryOverride;
  final void Function(String key, ImportDestination destination) onSubcategoryOverride;
  final void Function(String key, ImportDestination destination) onTagOverride;
  final Future<List<NamedEntity>> Function() loadExistingAccounts;
  final Future<List<NamedEntity>> Function({required bool isExpense}) loadExistingRootCategories;
  final Future<List<NamedEntity>> Function(String parentId) loadExistingSubcategories;
  final Future<List<NamedEntity>> Function() loadExistingTags;
  final VoidCallback onConfirm;

  /// Sends the user back to the mapping step (HU-05/06 bugfix): shown only
  /// in the "todas las filas son inválidas" empty state, where "Continuar"
  /// alone would silently walk into a preview with 0 valid rows. `null`
  /// hides the secondary action (e.g. when this step is exercised without a
  /// wizard around it, like a golden test).
  final VoidCallback? onReviewMapping;

  List<UnresolvedDestination> _collect() {
    final byKey = <String, UnresolvedDestination>{};
    for (final row in preview.rows) {
      final isExpense = row.type != ImportEntryType.income;
      _add(byKey, row.accountDestination, DestinationKind.account, LucideIcons.landmark, isExpense);
      _add(
        byKey,
        row.transferAccountDestination,
        DestinationKind.account,
        LucideIcons.landmark,
        isExpense,
      );
      _add(
        byKey,
        row.categoryDestination,
        DestinationKind.category,
        LucideIcons.shapes,
        isExpense,
      );
      _add(
        byKey,
        row.subcategoryDestination,
        DestinationKind.subcategory,
        LucideIcons.shapes,
        isExpense,
      );
      for (final tagDestination in row.tagDestinations) {
        _add(byKey, tagDestination, DestinationKind.tag, LucideIcons.tag, isExpense);
      }
    }
    return byKey.values.toList();
  }

  void _add(
    Map<String, UnresolvedDestination> byKey,
    ImportDestination? destination,
    DestinationKind kind,
    IconData icon,
    bool isExpense,
  ) {
    if (destination is! NewImportDestination) {
      return;
    }
    final key = kind == DestinationKind.subcategory
        ? '${normalizeForMatching(destination.parentName ?? '')}/${normalizeForMatching(destination.name)}'
        : normalizeForMatching(destination.name);
    if (byKey.containsKey(key)) {
      return;
    }
    byKey[key] = UnresolvedDestination(
      key: key,
      name: destination.name,
      icon: icon,
      kind: kind,
      isExpense: isExpense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final unresolved = _collect();

    if (unresolved.isEmpty) {
      // Nothing to resolve can mean two very different things: every row
      // matched *and* is valid (the good case, `importExportDestinationsNoneTitle`),
      // or every row is invalid — an invalid row never reaches an
      // `ImportDestination`, so it never shows up in `_collect()` either. A
      // mis-detected `tipo` column (bug fixed alongside this step, see
      // `autodetect_column_mapping.dart`) used to fail 100% of rows and land
      // here looking identical to "todo coincide" — this branch is what
      // stops that false positive from reaching the user.
      final invalidCount =
          preview.rows.where((r) => r.status == ImportRowStatus.invalid).length;
      final allInvalid = invalidCount > 0;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allInvalid ? LucideIcons.circleAlert : LucideIcons.circleCheck,
                size: 32,
                color: allInvalid ? colors.expenseText : colors.mintText,
              ),
              const SizedBox(height: 12),
              Text(
                allInvalid
                    ? l10n.importExportDestinationsAllInvalidTitle
                    : l10n.importExportDestinationsNoneTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (allInvalid) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.importExportDestinationsAllInvalidBody(invalidCount),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              if (allInvalid && onReviewMapping != null)
                NeutralButton(
                  label: l10n.importExportDestinationsReviewMappingCta,
                  icon: LucideIcons.arrowLeft,
                  onPressed: onReviewMapping!,
                )
              else
                NeutralButton(
                  label: l10n.commonContinue,
                  icon: LucideIcons.arrowRight,
                  onPressed: onConfirm,
                ),
            ],
          ),
        ),
      );
    }

    // HU-06 (`kYBYa`/`u8TSNH`): grouped by kind — accounts, then categories
    // and subcategories together under one "Categorías" header, then tags —
    // never a flat list, so the user reads what they're resolving in
    // context instead of a shuffled bag of names.
    final accounts = unresolved.where((d) => d.kind == DestinationKind.account).toList();
    final categories = unresolved
        .where((d) => d.kind == DestinationKind.category || d.kind == DestinationKind.subcategory)
        .toList();
    final tags = unresolved.where((d) => d.kind == DestinationKind.tag).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            children: [
              if (accounts.isNotEmpty) ...[
                Text(
                  l10n.importExportDestinationsSectionAccounts,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < accounts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  UnresolvedDestinationRow(
                    item: accounts[i],
                    overrides: accountOverrides,
                    onOverride: onAccountOverride,
                    loadExisting: loadExistingAccounts,
                  ),
                ],
                const SizedBox(height: 14),
              ],
              if (categories.isNotEmpty) ...[
                Text(
                  l10n.importExportDestinationsSectionCategories,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < categories.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  UnresolvedDestinationRow(
                    item: categories[i],
                    overrides: categories[i].kind == DestinationKind.category
                        ? categoryOverrides
                        : subcategoryOverrides,
                    onOverride: categories[i].kind == DestinationKind.category
                        ? onCategoryOverride
                        : onSubcategoryOverride,
                    loadExisting: categories[i].kind == DestinationKind.category
                        ? () => loadExistingRootCategories(isExpense: categories[i].isExpense)
                        : () => loadExistingSubcategories(''),
                  ),
                ],
                const SizedBox(height: 14),
              ],
              if (tags.isNotEmpty) ...[
                Text(
                  l10n.importExportDestinationsSectionTags,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < tags.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  UnresolvedDestinationRow(
                    item: tags[i],
                    overrides: tagOverrides,
                    onOverride: onTagOverride,
                    loadExisting: loadExistingTags,
                  ),
                ],
                const SizedBox(height: 14),
              ],
              PrivacyNoteStrip(text: l10n.importExportDestinationsNewAccountsNote),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: NeutralButton(
              label: l10n.commonContinue,
              icon: LucideIcons.arrowRight,
              onPressed: onConfirm,
            ),
          ),
        ),
      ],
    );
  }
}
