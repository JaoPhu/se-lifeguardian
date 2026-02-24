import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/user_repository.dart';
import '../domain/group_entity.dart';
import '../presentation/providers/group_provider.dart';

// Mocked providers to fix missing dependencies after refactor

final targetUsersProvider = Provider<List<GroupMemberEntity>>((ref) {
  final groupState = ref.watch(groupProvider);
  return groupState.members;
});

final activeTargetUidProvider = StateProvider<String?>((ref) => null);

final resolvedTargetUidProvider = Provider<String>((ref) {
  final activeTarget = ref.watch(activeTargetUidProvider);
  if (activeTarget != null && activeTarget.isNotEmpty) {
    return activeTarget;
  }
  final user = ref.watch(userProvider);
  return user.id;
});
