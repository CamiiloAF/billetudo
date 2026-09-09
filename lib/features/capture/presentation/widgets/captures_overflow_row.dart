import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `sCJCZ` — "Ver las otras N capturas".
///
/// The Avisos centre caps the captures section so that it and the notices
/// section both fit without scrolling on a real 390x844 phone. When the cap
/// has to bite, it is always the captures that are cut, never the notices:
/// a charge falling due has a consequence, a capture waiting has none.
class CapturesOverflowRow extends StatelessWidget {
  const CapturesOverflowRow({
    required this.hiddenCount,
    required this.onTap,
    super.key,
  });

  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primaryOnSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                LucideIcons.bellRing,
                size: 16,
                color: colors.primaryOnSoftStrong,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).captureOverflowLabel(hiddenCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryOnSoftStrong,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: colors.primaryOnSoftStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
