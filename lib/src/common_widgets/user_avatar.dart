import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor, width: 2),
        color: theme.cardColor,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? Icon(
              LucideIcons.user,
              size: radius,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            )
          : null,
    );
  }
}
