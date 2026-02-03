import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/notification_provider.dart';

class NotificationBell extends ConsumerWidget {
  final Color color;
  final bool whiteBorder;

  const NotificationBell({
    super.key, 
    this.color = Colors.white,
    this.whiteBorder = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final hasUnread = notificationState.unreadCount > 0;

    return GestureDetector(
      onTap: () { 
        context.push('/notifications');
        // We do NOT mark as read here immediately. 
        // Usually we mark as read when the user views the list or clicks a specific item.
        // For this requirement: "Clicking enters screen and clears dot" -> We can clear it in the screen's init or build.
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications, color: color, size: 24),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: whiteBorder 
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
