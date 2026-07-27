import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import 'page_header_circle_button.dart';

/// The Pencil `Dtm0X` "Page Header" component: a 44x44 circular back button
/// on the left, a centered bold title, and an optional 44x44 circular action
/// button on the right (or an invisible spacer of the same width so the
/// title stays centered when there is no action).
///
/// Used as a `Scaffold.appBar` replacement — put it in the body, above the
/// content, rather than passing it to `Scaffold(appBar: ...)`, since it is
/// not a `PreferredSizeWidget`.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.onBack,
    this.trailing,
    super.key,
  });

  /// Header title. Rendered centered, bold, `textPrimary`.
  final String title;

  /// Called when the back button is tapped. Defaults to `Navigator.pop`.
  final VoidCallback? onBack;

  /// Optional right-side action button (44x44, `primary` fill expected).
  /// When null, a `SizedBox(width: 44)` is reserved so the title stays
  /// centered.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          PageHeaderCircleButton(
            icon: LucideIcons.arrowLeft,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.commonBack,
            onPressed: onBack ?? Navigator.of(context).pop,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
          ),
          trailing ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}
