import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/group_entity.dart';
import '../../data/group_repository.dart';

class GroupState {
  final GroupEntity? currentGroup;
  final List<GroupMemberEntity> members;
  final List<JoinRequestEntity> pendingRequests;
  final bool isLoading;
  final String? errorMessage;

  GroupState({
    this.currentGroup,
    this.members = const [],
    this.pendingRequests = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  GroupState copyWith({
    GroupEntity? currentGroup,
    List<GroupMemberEntity>? members,
    List<JoinRequestEntity>? pendingRequests,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupState(
      currentGroup: currentGroup ?? this.currentGroup,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

class GroupNotifier extends StateNotifier<GroupState> {
  final GroupRepository repository;

  GroupNotifier(this.repository) : super(GroupState()) {
    refreshGroupData();
  }

  Future<void> refreshGroupData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final group = await repository.getCurrentGroup();
      final members = await repository.getMembers();
      final pendingReqs = await repository.getPendingRequests();

      state = state.copyWith(
        currentGroup: group,
        members: members,
        pendingRequests: pendingReqs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> createGroup(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.createGroup(name);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> joinGroup(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.joinGroup(code);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> changeGroupName(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.changeGroupName(name);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> approveRequest(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.approveRequest(userId);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> declineRequest(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.declineRequest(userId);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeMember(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.removeMember(userId);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> changeMemberRole(String userId, String newRole) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.changeMemberRole(userId, newRole);
      await refreshGroupData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return GroupNotifier(repo);
});
