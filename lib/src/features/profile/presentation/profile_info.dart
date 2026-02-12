import 'package:flutter/material.dart';
import '../../../common_widgets/user_avatar.dart';

class ProfileInfo extends StatelessWidget {
  final String name;
  final String username;
  final String avatarUrl;
  final VoidCallback? onEdit;

  const ProfileInfo({
    super.key,
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        // Avatar Section
        UserAvatar(
          avatarUrl: avatarUrl,
          radius: 50,
        ),
        const SizedBox(height: 12),
        // Info Section
        Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        Text(
          '@$username',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        // Edit Button
        if (onEdit != null)
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
