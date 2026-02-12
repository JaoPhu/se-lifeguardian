import '../domain/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications();
  Stream<List<NotificationModel>> watchNotifications({List<String> targetUids = const []});
  Future<void> addNotification(NotificationModel notification);
}

class NotificationRepositoryFirestore implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return NotificationModel.fromJson(data);
    }).toList();
  }

  @override
  Stream<List<NotificationModel>> watchNotifications({List<String> targetUids = const []}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    // Streams to combine: My own notifications + Subscriptions
    final streams = <Stream<List<NotificationModel>>>[];

    // 1. My notifications
    streams.add(_getNotificationStream(uid));

    // 2. Subscribed notifications (e.g. from people I follow/care for)
    // Note: The prompt says "Account in someone else's group will receive notifications of the group owner"
    // So if I am in Group A (Owned by Alice), I should see Alice's notifications.
    // 'targetUids' should contain ['alice_uid']
    for (final targetId in targetUids) {
      if (targetId != uid) {
        streams.add(_getNotificationStream(targetId));
      }
    }

    if (streams.isEmpty) return Stream.value([]);

    // Merge all streams and combine lists
    return Rx.combineLatest(streams, (List<List<NotificationModel>> values) {
      final allNotifications = <NotificationModel>[];
      for (final list in values) {
        allNotifications.addAll(list);
      }
      // Sort by date descending
      allNotifications.sort((a, b) => b.date.compareTo(a.date));
      return allNotifications;
    });
  }

  Stream<List<NotificationModel>> _getNotificationStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // If getting from another user, maybe tag it? 
        // For now, just return as is.
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(notification.toJson());
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryFirestore();
});

// We need a way to provide multiple streams.
// Updated provider is in notification_provider.dart
