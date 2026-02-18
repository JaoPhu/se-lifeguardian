import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final DateTime? createdAt;

  const JoinRequest({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory JoinRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return JoinRequest(
      uid: doc.id,
      displayName: (data['displayName'] ?? 'Unknown') as String,
      avatarUrl: (data['avatarUrl'] ?? '') as String,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : createdAt,
    };
  }
}
