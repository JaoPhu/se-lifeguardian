import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera.dart';

class CameraRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CameraRepository(this._firestore, this._auth, this._storage);

  // Get the camera collection for the proper user
  CollectionReference<Map<String, dynamic>>? _getCameraCollection(String targetUid) {
    if (targetUid.isEmpty) return null;
    return _firestore.collection('users').doc(targetUid).collection('cameras');
  }

  // Add or update a camera (Always saves to OWN account)
  Future<void> saveCamera(Camera camera) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final collection = _getCameraCollection(uid);
    if (collection == null) return;
    
    await collection.doc(camera.id).set(camera.toJson(), SetOptions(merge: true));
  }

  // Stream all cameras
  Stream<List<Camera>> watchCameras(String targetUid) {
    final collection = _getCameraCollection(targetUid);
    if (collection == null) return Stream.value([]);

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Camera.fromJson(doc.data())).toList();
    });
  }

  // Delete a camera (Always deletes from OWN account)
  Future<void> deleteCamera(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final collection = _getCameraCollection(uid);
    if (collection == null) return;

    await collection.doc(id).delete();
  }

  Future<String?> uploadThumbnail(String filePath, String cameraId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final extension = filePath.split('.').last;
      final ref = _storage.ref().child('users/$uid/cameras/$cameraId.$extension');
      
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$extension'),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // ✅ [Cloud Only] Delete local file after successful upload
      try {
        await file.delete();
        debugPrint('CameraRepository: Deleted local thumbnail after cloud sync: $filePath');
      } catch (e) {
        debugPrint('CameraRepository: Failed to delete local file: $e');
      }
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading camera thumbnail: $e');
      return null;
    }
  }
}

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepository(
    FirebaseFirestore.instance, 
    FirebaseAuth.instance,
    FirebaseStorage.instance,
  );
});
