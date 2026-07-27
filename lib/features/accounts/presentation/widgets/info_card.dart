import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Container of the detail's information rows: a `$surface` card that separates
/// its children with a hairline.
///
/// `_cornerRadius` is deliberately its own 20, not `AppTheme.radiusLarge`
/// (24) — that's what Pencil's `myfAc`-holding card uses, kept local until
/// Design decides whether it should become a shared token.
class InfoCard extends StatelessWidget {
  const InfoCard({required this.children, super.key});

  final List<Widget> children;

  static const _cornerRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 16),
            ],
            children[i],
          ],
        ],
      ),
    );
  }
}
