import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';

/// The mini card's 30×30 rounded-square type glyph (`r8QG5`): smaller and
/// squarer than the list's circular `AccountTypeAvatar`, but the same
/// icon+colour mapping via [AccountTypePresentation].
class MiniTypeIcon extends StatelessWidget {
  const MiniTypeIcon({required this.type, super.key});

  final AccountType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: type.softColor(colors),
        // `r8QG5` is a rounded square at radius 10 — smaller than any shared
        // token, so it stays a literal here.
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(type.icon, color: type.color(colors), size: 16),
    );
  }
}
