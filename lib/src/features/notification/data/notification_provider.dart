import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/notification_screen.dart';
import 'notification_repository.dart';

class NotificationState {
  final List<NotificationItem> notifications;

  NotificationState({required this.notifications});

  int get unreadCount => notifications.where((n) => n.isNew).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  StreamSubscription? _subscription;

  NotificationNotifier(this._repo) : super(NotificationState(notifications: [])) {
    _init();
  }

  void _init() async {
    // TODO: Fetch real subscribed UIDs from UserRepository or GroupRepository
    // For now, we simulate an empty list or a hardcoded one for testing if needed.
    // In a real app, this would be: 
    // final user = _ref.read(userRepositoryProvider).currentUser;
    // final initialTargets = user.subscribedTo ?? [];
    
    final List<String> targetUids = []; 
    // Example: targetUids.add('owner_uid_123');

    _subscription = _repo.watchNotifications(targetUids: targetUids).listen((models) {
      final items = models.map((m) {
        String uiType = 'info';
        if (m.type.name == 'success') uiType = 'success';
        if (m.type.name == 'warning') uiType = 'warning';
        if (m.type.name == 'danger') uiType = 'error';

        // simple logic: if created in last 5 mins, mark as new for now (or manage via local storage/firestore field)
        // For history, we just show them.
        final isNew = DateTime.now().difference(m.date).inMinutes < 5; 

        return NotificationItem(
          id: m.id,
          message: m.message,
          type: uiType,
          isNew: isNew,
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
        isNew: false, 
      );
    }).toList();
    state = NotificationState(notifications: updatedList);
  }

  Future<void> addNotification(NotificationItem item) async {
    // This might be used by Simulation/Logic to push local alerts to Firestore
    // But typically the backend or detector does this.
    // For now, we don't implementation writes here, as Repo handles it.
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repo);
});
