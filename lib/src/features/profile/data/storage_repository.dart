import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  /// Uploads a profile image to Firebase Storage and returns the download URL.
  Future<String> uploadProfileImage(String uid, File file) async {
    try {
      final ref = _storage.ref().child('users').child(uid).child('profile_pic.jpg');
      
      // Use putFile for reliable upload
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(FirebaseStorage.instance);
});
