import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../statistics/domain/simulation_event.dart';
import '../../group/providers/group_providers.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'demo_user';

  Future<String?> uploadSnapshot(String filePath, String eventId) async {
    final uid = currentUserId;

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final extension = filePath.split('.').last;
      final ref = _storage.ref().child('users/$uid/events/$eventId.$extension');
      
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$extension'),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // ✅ [Cloud Only] Delete local file after successful upload
      try {
        await file.delete();
        debugPrint('EventRepository: Deleted local snapshot after cloud sync: $filePath');
      } catch (e) {
        debugPrint('EventRepository: Failed to delete local file: $e');
      }
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading snapshot: $e');
      return null;
    }
  }
  Future<void> syncEvent(SimulationEvent event) async {
    final uid = currentUserId;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('events')
          .doc(event.id)
          .set(event.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Error syncing event: $e');
    }
  }

  Stream<List<SimulationEvent>> getEventsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('events')
        .orderBy('startTimeMs', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SimulationEvent.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> deleteEventsForCamera(String cameraId) async {
    final uid = currentUserId;

    try {
      final events = await _firestore
          .collection('users')
          .doc(uid)
          .collection('events')
          .where('cameraId', isEqualTo: cameraId)
          .get();

      final batch = _firestore.batch();
      for (var doc in events.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting camera events: $e');
    }
  }

  Future<void> deleteAllDataForUser() async {
    final uid = currentUserId;

    try {
      // 1. Delete all in 'events' subcollection (potentially large)
      await _deleteCollectionChunked(
          _firestore.collection('users').doc(uid).collection('events'));

      // 2. Delete all in 'history' subcollection
      await _deleteCollectionChunked(
          _firestore.collection('users').doc(uid).collection('history'));

      // 3. Delete all in 'cameras' subcollection
      await _deleteCollectionChunked(
          _firestore.collection('users').doc(uid).collection('cameras'));

      // 4. Delete all in 'notifications' subcollection
      await _deleteCollectionChunked(
          _firestore.collection('users').doc(uid).collection('notifications'));

      // 5. Reset root level health fields
      await _firestore.collection('users').doc(uid).set({
        'health_score': 1000,
        'health_status': 3, // HealthStatus.none enum index
        'last_activity': '',
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('EventRepository: All user health data wiped successfully.');
    } catch (e) {
      debugPrint('Error wiping user data: $e');
    }
  }

  /// Helper to delete all documents in a collection using multiple batches if needed.
  Future<void> _deleteCollectionChunked(CollectionReference collection) async {
    bool hasMore = true;
    while (hasMore) {
      final snapshot = await collection.limit(500).get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // If we got exactly 500, there might be more
      if (snapshot.docs.length < 500) {
        hasMore = false;
      }
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) => EventRepository());

final eventsStreamProvider = StreamProvider<List<SimulationEvent>>((ref) {
  // Watch active targetUid to ensure stream is recreated for the active patient
  final targetUid = ref.watch(resolvedTargetUidProvider);
  
  if (targetUid.isEmpty) return Stream.value([]);
  
  return ref.watch(eventRepositoryProvider).getEventsStream(targetUid);
});
