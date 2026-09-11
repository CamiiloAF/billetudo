import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../di/injection.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/page_header.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_kind.dart';
import '../../domain/usecases/resolve_legal_document.dart';
import '../widgets/legal_section.dart';

/// Native, in-app viewer for a legal document (Pencil `wwNqS`). One
/// parametrized screen for both [LegalDocumentKind]s — no second screen for
/// the privacy policy.
///
/// Reads ONLY local data (cache first, bundled asset fallback via
/// [ResolveLegalDocument]/`LegalDocumentsRepository`) and therefore never
/// shows a loading/error/empty state — it always has something to render the
/// instant it opens (`docs/legal/entrega-de-documentos-legales.md`).
///
/// Reached both from the acceptance/re-acceptance sheets' `Legal Doc Row`
/// (the sheet stays underneath, this is pushed on top) and from Ajustes'
/// legal links — same screen, same back arrow, never a "x".
class LegalDocumentViewerPage extends StatefulWidget {
  const LegalDocumentViewerPage({required this.kind, super.key});

  final LegalDocumentKind kind;

  /// Pushes this screen on the ROOT navigator: both entry points (a sheet's
  /// doc row, and Ajustes' legal links) must stack above a sheet or the tab
  /// bar rather than being scoped to the current branch navigator.
  static Future<void> push(BuildContext context, LegalDocumentKind kind) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => LegalDocumentViewerPage(kind: kind),
        ),
      );

  @override
  State<LegalDocumentViewerPage> createState() =>
      _LegalDocumentViewerPageState();
}

class _LegalDocumentViewerPageState extends State<LegalDocumentViewerPage> {
  late final Future<LegalDocument> _document =
      getIt<ResolveLegalDocument>()(kind: widget.kind).then(
    (result) => result.fold(
      (failure) => throw StateError(failure.message),
      (document) => document,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final title = widget.kind == LegalDocumentKind.termsOfUse
        ? l10n.settingsTermsOfUse
        : l10n.settingsPrivacyPolicy;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FutureBuilder<LegalDocument>(
          future: _document,
          builder: (context, snapshot) {
            final document = snapshot.data;
            if (document == null) {
              // The future only fails on a bug (both cache and bundle
              // missing); nothing local to render yet — no spinner per the
              // "never blocks" rule, just the header until the microtask
              // above resolves (near-instant, purely local reads).
              return Column(
                children: [PageHeader(title: title)],
              );
            }
            final formattedDate = DateFormat(
              "d 'de' MMMM 'de' y",
              locale,
            ).format(document.effectiveDate);
            final sections = parseLegalSections(document.content);
            return Column(
              children: [
                PageHeader(title: title),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.legalViewerMeta(
                        document.legalVersion,
                        formattedDate,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                    ),
                  ),
                ),
                Container(height: 1, color: colors.border),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 22),
                    itemBuilder: (context, index) => LegalSectionView(
                      section: sections[index],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
