import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/entities/auth_user.dart';
import '../account_avatar.dart';

/// `AccountSheet`'s signed-in identity block: avatar + display name + email.
class IdentityRow extends StatelessWidget {
  const IdentityRow({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final name = user.displayName;
    final email = user.email;
    final initial = name.trim().isEmpty ? null : name.trim()[0].toUpperCase();

    return Row(
      children: [
        AccountAvatar(badge: AccountAvatarBadge.synced, initial: initial),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (email != null)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
