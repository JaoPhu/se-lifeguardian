import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String ownerUid;
  final String inviteCode;
  final DateTime? createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.inviteCode,
    required this.createdAt,
  });

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return Group(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      ownerUid: (data['ownerUid'] ?? '') as String,
      inviteCode: (data['inviteCode'] ?? '') as String,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'inviteCode': inviteCode,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : createdAt,
    };
  }
}
