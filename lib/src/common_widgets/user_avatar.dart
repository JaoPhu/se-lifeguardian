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
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  LucideIcons.user,
                  size: radius,
                  color: theme.iconTheme.color?.withValues(alpha: 0.5),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            )
          : Icon(
              LucideIcons.user,
              size: radius,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
    );
  }
}
