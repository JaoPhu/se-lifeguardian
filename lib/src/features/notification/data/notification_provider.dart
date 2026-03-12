import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/notification_screen.dart';
import 'notification_repository.dart';
import '../../group/providers/group_providers.dart';

class NotificationState {
  final List<NotificationItem> notifications;

  NotificationState({required this.notifications});

  int get unreadCount => notifications.where((n) => n.isNew).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  StreamSubscription? _subscription;

  NotificationNotifier(this._repo) : super(NotificationState(notifications: []));

  void updateTarget(String targetUid) {
    _subscription?.cancel();
    
    final effectiveUid = targetUid.isEmpty ? 'demo_user' : targetUid;
    final List<String> targetUids = [effectiveUid]; 

    _subscription = _repo.watchNotifications(targetUids: targetUids).listen((models) {
      final items = models.map((m) {
        String uiType = 'info';
        if (m.type.name == 'success') uiType = 'success';
        if (m.type.name == 'warning') uiType = 'warning';
        if (m.type.name == 'danger') uiType = 'error';

        // For history, simple check if it is new
        final isNew = DateTime.now().difference(m.date).inMinutes < 5;
        
        // Format time for display
        final h = m.date.hour.toString().padLeft(2, '0');
        final min = m.date.minute.toString().padLeft(2, '0');
        final d = m.date.day.toString().padLeft(2, '0');
        final mo = m.date.month.toString().padLeft(2, '0');
        final timeStr = '$h:$min  $d/$mo/${m.date.year}';

        return NotificationItem(
          id: m.id,
          message: m.message,
          type: uiType,
          isNew: isNew,
          time: timeStr,
        );
      }).toList();

      state = NotificationState(notifications: items);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void markAllAsRead() {
    final updatedList = state.notifications.map((n) {
      return NotificationItem(
        id: n.id,
        message: n.message,
        type: n.type,
        time: n.time,
        isNew: false, 
      );
    }).toList();
    state = NotificationState(notifications: updatedList);
  }

  void removeNotification(String id) {
    state = NotificationState(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
    // Also delete from Firestore
    _repo.deleteNotification(id);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final notifier = NotificationNotifier(repo);

  ref.listen<String>(resolvedTargetUidProvider, (previous, next) {
    notifier.updateTarget(next);
  }, fireImmediately: true);
  
  return notifier;
});
