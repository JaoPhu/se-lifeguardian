import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../authentication/providers/auth_providers.dart';
import '../data/group_repository.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';
import '../domain/join_request.dart';
import '../../profile/data/user_repository.dart';

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
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);
  
  return ref.watch(groupRepoProvider).watchOwnerGroupId(user.uid);
});

final ownerGroupProvider = StreamProvider<Group?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);

  return ref.watch(groupRepoProvider).watchMyOwnerGroup(user.uid);
});

final groupMembersProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupRepoProvider).watchMembers(groupId);
});

final joinRequestsProvider =
    StreamProvider.family<List<JoinRequest>, String>((ref, groupId) {
  return ref.watch(groupRepoProvider).watchJoinRequests(groupId);
});

class TargetUser {
  final String uid;
  final String name;
  final bool isSelf;

  TargetUser({required this.uid, required this.name, this.isSelf = false});
}

// targetUsersProvider provides a list of TargetUser (Self + all joined group owners)
final targetUsersProvider = FutureProvider<List<TargetUser>>((ref) async {
  final user = ref.watch(userProvider);
  
  if (user.id.isEmpty) return [];

  final List<TargetUser> targets = [
    TargetUser(uid: user.id, name: "${user.name.isNotEmpty ? user.name : 'Unknown User'} (Me)", isSelf: true)
  ];

  if (user.joinedGroupIds.isNotEmpty) {
    try {
      final futures = user.joinedGroupIds.map((groupId) => Future.wait([
        FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
        FirebaseFirestore.instance.collection('groups').doc(groupId).collection('members').doc(user.id).get()
      ]));
      
      final snapshotPairs = await Future.wait(futures);
      
      for (final pair in snapshotPairs) {
        final doc = pair[0];
        final memberDoc = pair[1];
        if (doc.exists && memberDoc.exists) {
          final data = doc.data() ?? {};
          final ownerUid = data['ownerUid'] as String?;
          final groupName = data['name'] as String? ?? 'Unknown Group';
          
          if (ownerUid != null && ownerUid.isNotEmpty && !targets.any((t) => t.uid == ownerUid)) {
            targets.add(TargetUser(uid: ownerUid, name: "$groupName (Owner)"));
          }
        }
      }
    } catch (e) {
      print('Error fetching joined groups owner UIDs: $e');
    }
  }
  
  return targets;
});

// Stores the currently selected patient UID from the dropdown
final activeTargetUidProvider = StateProvider<String?>((ref) => null);

// Resolves the currently active UID: uses the selected one, or defaults to the user's own ID
final resolvedTargetUidProvider = Provider<String>((ref) {
  final selected = ref.watch(activeTargetUidProvider);
  if (selected != null) return selected;
  
  return ref.watch(userProvider).id;
});
