import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Which of the two possible-duplicate answers a [DuplicateActionButton]
/// renders. Deliberately required everywhere it is used — there is no
/// default, because a false positive on the wrong one erases a real expense.
enum DuplicateActionVariant {
  /// "Es la misma" (`Pm2sj`): DOES something — discards the capture, with an
  /// undo snackbar. `$muted`, so the color never pushes the user towards the
  /// answer that executes.
  same,

  /// "Es otra compra" (`qkq49`): does NOT write anything by itself — it
  /// opens the pre-filled form, where the user sees everything again and can
  /// still back out. Solid `$primary`, the same treatment as any other
  /// primary action in the app.
  different,
}

/// `Pm2sj`/`qkq49` — one of the two answers to a possible duplicate.
///
/// **Asymmetric by role, not by importance** (2026-09-09 rebuild): the two
/// used to share one flat `$surface` + 50% stroke treatment that read as
/// neither one being a real action. Now the color tells the user which path
/// *executes* ([DuplicateActionVariant.same]) and which one only opens a form
/// they can still leave ([DuplicateActionVariant.different]) — the opposite
/// of pushing them towards the discard, which is the costly mistake here.
class DuplicateActionButton extends StatelessWidget {
  const DuplicateActionButton({
    required this.label,
    required this.variant,
    required this.onPressed,
    super.key,
  });

  final String label;
  final DuplicateActionVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSame = variant == DuplicateActionVariant.same;
    return SizedBox(
      height: 44,
      child: Material(
        color: isSame ? colors.muted : colors.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSame ? colors.textPrimary : colors.onPrimary,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
