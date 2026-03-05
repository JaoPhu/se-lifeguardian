import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../authentication/providers/auth_providers.dart';
import '../data/group_repository.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';
import '../domain/join_request.dart';
import '../../profile/data/user_repository.dart';
import 'package:rxdart/rxdart.dart';

final joinedGroupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(userProvider);
  if (user.joinedGroupIds.isEmpty) return Stream.value([]);
  
  // We need to double-check membership for each group in joinedGroupIds
  // because some might be "Pending" (requested but not approved).
  // We watch the group documents AND our member document in each.
  
  final streams = user.joinedGroupIds.map((id) {
    return FirebaseFirestore.instance.collection('groups').doc(id).snapshots().asyncMap((groupDoc) async {
       if (!groupDoc.exists) return null;
       
       // Verify we are actually in the members subcollection
       final memberDoc = await groupDoc.reference.collection('members').doc(user.id).get();
       if (!memberDoc.exists) return null; // Not approved yet
       
       return Group.fromDoc(groupDoc);
    });
  });
  
  return Rx.combineLatestList(streams).map((groups) {
    return groups
        .where((g) => g != null)
        .cast<Group>()
        .toList();
  });
});

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
        final groupDoc = pair[0];
        final memberDoc = pair[1];
        if (groupDoc.exists && memberDoc.exists) {
          final groupData = groupDoc.data() ?? {};
          final memberData = memberDoc.data() ?? {};
          
          final ownerUid = groupData['ownerUid'] as String?;
          final groupName = groupData['name'] as String? ?? 'Unknown Group';
          final myRole = memberData['role'] as String? ?? 'Member';
          
          // Capitalize first letter of role
          final roleLabel = myRole.isNotEmpty 
              ? myRole[0].toUpperCase() + myRole.substring(1) 
              : 'Member';
          
          if (ownerUid != null && ownerUid.isNotEmpty && !targets.any((t) => t.uid == ownerUid)) {
            targets.add(TargetUser(uid: ownerUid, name: "$groupName ($roleLabel)"));
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
  
  final userId = ref.watch(userProvider).id;
  return userId.isNotEmpty ? userId : 'demo_user';
});
