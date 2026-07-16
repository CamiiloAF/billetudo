import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/account.dart';

/// Icon, colour and name of an account type.
///
/// The design deliberately dropped the icon/colour picker: every account gets a
/// **standard** look derived from its type, so this is the one place that
/// decides it. Each colour is paired with its own `-soft` background, the pair
/// MASTER.md verifies at 3:1.
extension AccountTypePresentation on AccountType {
  IconData get icon => switch (this) {
        AccountType.cash => LucideIcons.banknote,
        AccountType.bank => LucideIcons.landmark,
        AccountType.card => LucideIcons.creditCard,
        AccountType.savings => LucideIcons.piggyBank,
        AccountType.investment => LucideIcons.trendingUp,
        AccountType.other => LucideIcons.wallet,
      };

  /// Colour of the icon itself. `primary` is read through `primaryOnSoft`,
  /// which is the token that survives dark mode on a soft background.
  Color color(AppColors colors) => switch (this) {
        AccountType.cash => colors.mint,
        AccountType.bank => colors.sky,
        AccountType.card => colors.primaryOnSoft,
        AccountType.savings => colors.teal,
        AccountType.investment => colors.indigo,
        AccountType.other => colors.peach,
      };

  Color softColor(AppColors colors) => switch (this) {
        AccountType.cash => colors.mintSoft,
        AccountType.bank => colors.skySoft,
        AccountType.card => colors.primarySoft,
        AccountType.savings => colors.tealSoft,
        AccountType.investment => colors.indigoSoft,
        AccountType.other => colors.peachSoft,
      };

  String label(AppLocalizations l10n) => switch (this) {
        AccountType.cash => l10n.accountTypeCash,
        AccountType.bank => l10n.accountTypeBank,
        AccountType.card => l10n.accountTypeCard,
        AccountType.savings => l10n.accountTypeSavings,
        AccountType.investment => l10n.accountTypeInvestment,
        AccountType.other => l10n.accountTypeOther,
      };
}

/// The circular icon that identifies an account by its type.
class AccountTypeAvatar extends StatelessWidget {
  const AccountTypeAvatar({required this.type, this.size = 44, super.key});

  final AccountType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.softColor(colors),
        // MASTER.md: a circular icon-wrap uses half its height as radius.
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(type.icon, color: type.color(colors), size: size * 0.45),
    );
  }
}
