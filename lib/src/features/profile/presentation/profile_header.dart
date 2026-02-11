import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;

  const ProfileHeader({super.key, required this.onBack, this.title = 'Profile'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 12, bottom: 2),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(LucideIcons.arrowLeft, color: theme.iconTheme.color, size: 20),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}
