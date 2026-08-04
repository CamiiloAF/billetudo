import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/account.dart';
import 'account_type_avatar.dart';

/// One row of `AccountTypePickerSheet`: icon, name, and a check when selected
/// — the same list-row pattern `CurrencyRow` uses for the currency picker.
class AccountTypeRow extends StatelessWidget {
  const AccountTypeRow({
    required this.type,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final AccountType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AccountTypeAvatar(type: type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label(l10n),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.check, color: colors.primaryOnSoft, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
