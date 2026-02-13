import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  /// Uploads a profile image to Firebase Storage and returns the download URL.
  /// Accepts either File (mobile) or XFile (web)
  Future<String> uploadProfileImage(String uid, dynamic file) async {
    try {
      final ref = _storage.ref().child('users').child(uid).child('profile_pic.jpg');
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web: Use XFile and putData
        final XFile xFile = file as XFile;
        final bytes = await xFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Mobile: Use File and putFile
        final File ioFile = file as File;
        uploadTask = ref.putFile(
          ioFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
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
