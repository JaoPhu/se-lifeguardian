import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera.dart';

class CameraRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CameraRepository(this._firestore, this._auth);

  // Get the camera collection for the current user
  CollectionReference<Map<String, dynamic>>? _getCameraCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('cameras');
  }

  // Add or update a camera
  Future<void> saveCamera(Camera camera) async {
    final collection = _getCameraCollection();
    if (collection == null) return;
    
    await collection.doc(camera.id).set(camera.toJson(), SetOptions(merge: true));
  }

  // Stream all cameras
  Stream<List<Camera>> watchCameras() {
    final collection = _getCameraCollection();
    if (collection == null) return Stream.value([]);

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Camera.fromJson(doc.data())).toList();
    });
  }

  // Delete a camera
  Future<void> deleteCamera(String id) async {
    final collection = _getCameraCollection();
    if (collection == null) return;

    await collection.doc(id).delete();
  }
}

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});
