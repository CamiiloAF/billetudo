import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../domain/entities/legal_document_kind.dart';
import '../pages/legal_document_viewer_page.dart';
import 'legal_text_link.dart';

/// Bienvenida's discreet legal footer (`E4mWb`/`fRrDQ`): two `Legal Text
/// Link` (`c1dEc`) instances separated by a dot, opening the native document
/// viewer directly — no external browser.
///
/// This only satisfies the "documents are reachable" requirement; it does
/// NOT record acceptance. The explicit "Acepto" flow lives in
/// `LegalAcceptanceSheet`.
class LegalFooterLinks extends StatelessWidget {
  const LegalFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LegalTextLink(
          label: l10n.settingsTermsOfUse,
          onTap: () => LegalDocumentViewerPage.push(
            context,
            LegalDocumentKind.termsOfUse,
          ),
        ),
        Text(
          '·',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        LegalTextLink(
          label: l10n.settingsPrivacyPolicy,
          onTap: () => LegalDocumentViewerPage.push(
            context,
            LegalDocumentKind.privacyPolicy,
          ),
        ),
      ],
    );
  }
}
