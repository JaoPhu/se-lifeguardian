import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String uid;
  final String role; // owner/admin/viewer
  final String displayName;
  final String avatarUrl;
  final DateTime? joinedAt;

  const GroupMember({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.avatarUrl,
    required this.joinedAt,
  });

  factory GroupMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['joinedAt'];
    return GroupMember(
      uid: doc.id,
      role: (data['role'] ?? 'viewer') as String,
      displayName: (data['displayName'] ?? 'Unknown') as String,
      avatarUrl: (data['avatarUrl'] ?? '') as String,
      joinedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'joinedAt': joinedAt == null ? FieldValue.serverTimestamp() : joinedAt,
    };
  }
}
