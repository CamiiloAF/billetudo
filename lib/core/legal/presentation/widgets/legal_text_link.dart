import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// The Pencil `Legal Text Link` (`c1dEc`): a discreet, no-background link
/// with a `[14,8]` padding that gives it a 44px tap target. Used by
/// `LegalFooterLinks` and by the acceptance sheet's legal footer.
class LegalTextLink extends StatelessWidget {
  const LegalTextLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.primaryOnSoftStrong,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
      ),
    );
  }
}
