import '../domain/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications();
  Stream<List<NotificationModel>> watchNotifications({List<String> targetUids = const []});
  Future<void> addNotification(NotificationModel notification, {String? targetUid});
  Future<void> deleteNotification(String id);
}

class NotificationRepositoryFirestore implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'demo_user';

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    final uid = _uid;

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
    final authUid = _uid;
    
    // Check if we are in demo mode (logged in as demo_user)
    if (authUid == 'demo_user') {
      if (targetUids.isEmpty) return Stream.value([]);
      return _getNotificationStream(targetUids.first);
    }

    final streams = <Stream<List<NotificationModel>>>[];

    // 1. My own notifications
    streams.add(_getNotificationStream(authUid));

    // 2. Subscribed notifications
    for (final targetId in targetUids) {
      if (targetId != authUid) {
        streams.add(_getNotificationStream(targetId));
      }
    }

    if (streams.isEmpty) return Stream.value([]);

    return Rx.combineLatest(streams, (List<List<NotificationModel>> values) {
      final allNotifications = <NotificationModel>[];
      for (final list in values) {
        allNotifications.addAll(list);
      }
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
  Future<void> addNotification(NotificationModel notification, {String? targetUid}) async {
    final uid = targetUid ?? _uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(notification.toJson());
  }

  @override
  Future<void> deleteNotification(String id) async {
    final uid = _uid;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      // Ignore delete errors (item may already be gone)
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryFirestore();
});

// We need a way to provide multiple streams.
// Updated provider is in notification_provider.dart
