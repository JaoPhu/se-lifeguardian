import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/notification_screen.dart'; // Import NotificationItem class

class NotificationState {
  final List<NotificationItem> notifications;

  NotificationState({required this.notifications});

  int get unreadCount => notifications.where((n) => n.isNew).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState(notifications: [
    // Initial Mock Data
      NotificationItem(
        id: '1',
        message: 'Your health signal is stable for the last 24 hours.',
        type: 'success',
        isNew: true,
      ),
      NotificationItem(
        id: '2',
        message: 'Suspicious movement detected at 3:15 PM.',
        type: 'warning',
        isNew: true,
      ),
      NotificationItem(
        id: '3',
        message: 'System update completed successfully.',
        type: 'success',
      ),
      NotificationItem(
        id: '4',
        message: 'Emergency contact "Dad" has been notified.',
        type: 'error',
      ),
  ]));

  void markAllAsRead() {
    final updatedList = state.notifications.map((n) {
      return NotificationItem(
        id: n.id,
        message: n.message,
        type: n.type,
        isNew: false, 
      );
    }).toList();
    state = NotificationState(notifications: updatedList);
  }

  void addNotification(NotificationItem item) {
    state = NotificationState(notifications: [item, ...state.notifications]);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
