import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// One check bullet of the envelope info sheet (`eBwb0/stMuq`): a 22pt
/// `$primary-soft` dot with a 14pt `$primary-on-soft` check, then a wrapping
/// 14/500 line in `$text-primary`.
class EnvelopeInfoBullet extends StatelessWidget {
  const EnvelopeInfoBullet({required this.text, super.key});

  /// Already localized.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.check,
            size: 14,
            color: colors.primaryOnSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
