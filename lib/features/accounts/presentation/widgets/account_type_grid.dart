import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/account.dart';
import 'account_type_avatar.dart';

/// The grid of six `Category Chip`s that picks an account type.
class AccountTypeGrid extends StatelessWidget {
  const AccountTypeGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// `null` on a new account: the grid starts neutral, nothing preselected.
  final AccountType? selected;

  final ValueChanged<AccountType> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final type in AccountType.values)
          AccountTypeChip(
            type: type,
            isSelected: type == selected,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

/// One `Category Chip`: icon in a circle with its name underneath.
class AccountTypeChip extends StatelessWidget {
  const AccountTypeChip({
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? colors.primarySoft : colors.muted,
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? Border.all(color: colors.primary) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AccountTypeAvatar(type: type, size: 40),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  type.label(l10n),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        // 13px over `primary-soft` needs the strong token to
                        // clear 4.5:1 (MASTER.md, Category Chip).
                        color: isSelected
                            ? colors.primaryOnSoftStrong
                            : colors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
