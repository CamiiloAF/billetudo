import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/account.dart';
import 'account_type_avatar.dart';

/// The collapsed type selector of the edit form (`xdLeB`): icon + name +
/// "Cambiar".
///
/// Tapping expands the grid **inline**, pushing the rest of the form down — a
/// bottom sheet was considered and rejected. The animation lives in
/// `AccountFormPage`, via `AnimatedSize`.
class AccountTypePill extends StatelessWidget {
  const AccountTypePill({
    required this.type,
    required this.onChange,
    super.key,
  });

  final AccountType type;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          AccountTypeAvatar(type: type, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type.label(l10n),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              l10n.accountFormTypeChange,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primaryOnSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
