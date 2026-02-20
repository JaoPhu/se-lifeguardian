import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String uid;
  final String role; // owner/caretaker/member
  final String displayName;
  final String username;
  final String avatarUrl;
  final DateTime? joinedAt;

  const GroupMember({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.joinedAt,
  });

  factory GroupMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['joinedAt'];
    return GroupMember(
      uid: doc.id,
      role: (data['role'] ?? 'member') as String,
      displayName: (data['displayName'] ?? 'Unknown') as String,
      username: (data['username'] ?? '') as String,
      avatarUrl: (data['avatarUrl'] ?? '') as String,
      joinedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'joinedAt': joinedAt == null ? FieldValue.serverTimestamp() : joinedAt,
    };
  }
}
