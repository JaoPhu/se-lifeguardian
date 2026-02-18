import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../statistics/domain/simulation_event.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String?> uploadSnapshot(String filePath, String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final extension = filePath.split('.').last;
      final ref =
          _storage.ref().child('users/${user.uid}/events/$eventId.$extension');

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$extension'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading snapshot: $e');
      return null;
    }
  }

  Future<void> syncEvent(SimulationEvent event) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('EventRepository: Cannot sync event, user is null.');
      return;
    }

    try {
      print(
          'EventRepository: Syncing event ${event.id} (${event.type}) to Firestore...');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .doc(event.id)
          .set(event.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Error syncing event: $e');
    }
  }

  Stream<List<SimulationEvent>> getEventsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      print('EventRepository: User is null, returning empty stream.');
      return Stream.value([]);
    }

    print('EventRepository: Listening to events for user ${user.uid}');
    return _firestore
        .collection('users')
        .doc(user.uid)
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
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final events = await _firestore
          .collection('users')
          .doc(user.uid)
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
}

final eventRepositoryProvider =
    Provider<EventRepository>((ref) => EventRepository());

final eventsStreamProvider = StreamProvider<List<SimulationEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).getEventsStream();
});
