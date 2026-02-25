import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/group.dart';
import '../domain/group_member.dart';
import '../domain/join_request.dart';

class GroupRepository {
  GroupRepository({
    required FirebaseFirestore db,
    required FirebaseAuth auth,
  })  : _db = db,
        _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  final _random = Random.secure();

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _groupRef(String groupId) =>
      _db.collection('groups').doc(groupId);

  CollectionReference<Map<String, dynamic>> _membersCol(String groupId) =>
      _groupRef(groupId).collection('members');

  CollectionReference<Map<String, dynamic>> _requestsCol(String groupId) =>
      _groupRef(groupId).collection('join_requests');

  // ---------- OWNER GROUP ID (stored in users/{uid}.ownerGroupId) ----------
  Stream<String?> watchOwnerGroupId(String uid) {
    return _userRef(uid).snapshots().map((snap) {
      final data = snap.data() ?? {};
      return data['ownerGroupId'] as String?;
    });
  }

  Future<String?> getOwnerGroupId() async {
    final snap = await _userRef(_uid).get();
    final data = snap.data() ?? {};
    return data['ownerGroupId'] as String?;
  }

  // ---------- GROUP ----------
  Stream<Group?> watchMyOwnerGroup(String uid) {
    return watchOwnerGroupId(uid).asyncMap((groupId) async {
      if (groupId == null) return null;
      final doc = await _groupRef(groupId).get();
      if (!doc.exists) return null;
      return Group.fromDoc(doc);
    });
  }

  // create owner group (ถ้ายังไม่มี)
  Future<String> createOwnerGroup({required String name}) async {
    final uid = _uid;
    final userSnap = await _userRef(uid).get();
    final currentOwnerGroupId = (userSnap.data() ?? {})['ownerGroupId'] as String?;
    if (currentOwnerGroupId != null) {
      return currentOwnerGroupId; // มีแล้ว
    }

    final code = _genCode();
    final newGroupDoc = _db.collection('groups').doc();
    final groupId = newGroupDoc.id;

    // อ่าน user profile สั้นๆ ไปแสดงใน member list
    final data = userSnap.data() ?? {};
    final displayName = data['name'] as String? ?? 'Unknown';
    final username = data['username'] as String? ?? '';
    final avatarUrl = data['avatarUrl'] as String? ?? '';

    // If name is the default "My Group", use nickname's group instead
    String finalGroupName = name;
    if (finalGroupName == 'My Group' && username.isNotEmpty) {
      finalGroupName = "$username's group";
    }

    await _db.runTransaction((tx) async {
      tx.set(newGroupDoc, {
        'name': finalGroupName,
        'ownerUid': uid,
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
        'inviteUpdatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(_membersCol(groupId).doc(uid), {
        'role': 'owner',
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      tx.set(_userRef(uid), {
        'ownerGroupId': groupId,
      }, SetOptions(merge: true));
    });

    return groupId;
  }

  Future<void> regenerateInviteCode(String groupId) async {
    final code = _genCode();
    await _groupRef(groupId).update({
      'inviteCode': code,
      'inviteUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroupName(String groupId, String name) async {
    await _groupRef(groupId).update({
      'name': name.trim(),
    });
  }

  // ---------- MEMBERS / REQUESTS STREAM ----------
  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _membersCol(groupId)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => GroupMember.fromDoc(d)).toList());
  }

  Stream<List<JoinRequest>> watchJoinRequests(String groupId) {
    return _requestsCol(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => JoinRequest.fromDoc(d)).toList());
  }

  // ---------- JOIN FLOW ----------
  /// สมาชิก: กรอก invite code -> สร้าง join request ใต้ group
  Future<void> requestJoinByCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) throw Exception('Invite code is empty');

    final q = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: c)
        .limit(1)
        .get();

    if (q.docs.isEmpty) throw Exception('Invalid invite code');

    final groupId = q.docs.first.id;

    // ดึง user profile
    final userSnap = await _userRef(_uid).get();
    final u = userSnap.data() ?? {};
    final displayName = (u['name'] as String?) ?? 'Unknown';
    final username = (u['username'] as String?) ?? '';
    final avatarUrl = (u['avatarUrl'] as String?) ?? '';

    // ถ้าเป็นสมาชิกอยู่แล้ว ไม่ต้องขอซ้ำ
    final alreadyMember = await _membersCol(groupId).doc(_uid).get();
    if (alreadyMember.exists) return;

    await _db.runTransaction((tx) async {
      tx.set(_requestsCol(groupId).doc(_uid), {
        'uid': _uid,
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(_userRef(_uid), {
        'joinedGroupIds': FieldValue.arrayUnion([groupId]),
      }, SetOptions(merge: true));
    });
  }

  /// owner/admin: approve -> ย้าย request ไป members
  Future<void> approveRequest({
    required String groupId,
    required String targetUid,
    String role = 'member',
  }) async {
    final targetUser = await _userRef(targetUid).get();
    final u = targetUser.data() ?? {};
    final displayName = (u['name'] as String?) ?? 'Unknown';
    final username = (u['username'] as String?) ?? '';
    final avatarUrl = (u['avatarUrl'] as String?) ?? '';

    final memberRef = _membersCol(groupId).doc(targetUid);
    final reqRef = _requestsCol(groupId).doc(targetUid);

    await _db.runTransaction((tx) async {
      tx.set(memberRef, {
        'role': role,
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.delete(reqRef);
    });
  }

  Future<void> declineRequest({
    required String groupId,
    required String targetUid,
  }) async {
    await _requestsCol(groupId).doc(targetUid).delete();
  }

  // ---------- ROLE / REMOVE ----------
  Future<void> changeRole({
    required String groupId,
    required String targetUid,
    required String role,
  }) async {
    await _membersCol(groupId).doc(targetUid).update({'role': role});
  }

  Future<void> removeMember({
    required String groupId,
    required String targetUid,
  }) async {
    await _membersCol(groupId).doc(targetUid).delete();
  }

  // ---------- HELPERS ----------
  String _genCode() {
    final num = 1000 + _random.nextInt(9000); // 1000-9999
    return 'LG-$num';
  }
}
