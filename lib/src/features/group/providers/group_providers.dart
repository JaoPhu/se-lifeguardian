import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/group_repository.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';
import '../domain/join_request.dart';

final _firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final _authProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final groupRepoProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(
    db: ref.watch(_firestoreProvider),
    auth: ref.watch(_authProvider),
  );
});

final ownerGroupIdProvider = StreamProvider<String?>((ref) {
  return ref.watch(groupRepoProvider).watchOwnerGroupId();
});

final ownerGroupProvider = StreamProvider<Group?>((ref) {
  return ref.watch(groupRepoProvider).watchMyOwnerGroup();
});

final groupMembersProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupRepoProvider).watchMembers(groupId);
});

final joinRequestsProvider =
    StreamProvider.family<List<JoinRequest>, String>((ref, groupId) {
  return ref.watch(groupRepoProvider).watchJoinRequests(groupId);
});
