
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import 'notification_repository.dart';

// 4. NotificationRepository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryMock();
});

// 5. NotificationList Provider (FutureProvider)
final notificationListProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.fetchNotifications();
});
