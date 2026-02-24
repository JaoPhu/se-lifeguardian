import '../domain/group_entity.dart';

class GroupRepository {
  // Mock in-memory data
  GroupEntity? _currentGroup;
  List<GroupMemberEntity> _members = [];
  List<JoinRequestEntity> _pendingRequests = [];

  GroupRepository() {
    _initMockData();
  }

  void _initMockData() {
    _currentGroup = const GroupEntity(
      id: 'g1',
      name: 'Super Team',
      inviteCode: 'LG-9821',
    );
    _members = [
      const GroupMemberEntity(id: 'u1', name: 'Alice (Me)', role: 'Owner'),
      const GroupMemberEntity(id: 'u2', name: 'Bob', role: 'Admin'),
      const GroupMemberEntity(id: 'u3', name: 'Charlie', role: 'Viewer'),
    ];
    _pendingRequests = [
      const JoinRequestEntity(userId: 'u4', name: 'Dave'),
      const JoinRequestEntity(userId: 'u5', name: 'Eve'),
    ];
  }

  Future<void> createGroup(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentGroup = GroupEntity(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      inviteCode: 'LG-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}',
    );
    _members = [
      const GroupMemberEntity(id: 'u1', name: 'Alice (Me)', role: 'Owner'),
    ];
    _pendingRequests = [];
  }

  Future<void> joinGroup(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!RegExp(r'^LG-\d{4}$').hasMatch(code)) {
      throw Exception('Invalid invite code format (e.g. LG-1234)');
    }
    _pendingRequests.add(const JoinRequestEntity(userId: 'u_me', name: 'Alice (Me)'));
  }

  Future<void> changeGroupName(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentGroup != null) {
      _currentGroup = _currentGroup!.copyWith(name: name);
    }
  }

  Future<void> approveRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final reqIndex = _pendingRequests.indexWhere((r) => r.userId == userId);
    if (reqIndex != -1) {
      final req = _pendingRequests[reqIndex];
      _pendingRequests.removeAt(reqIndex);
      _members.add(GroupMemberEntity(id: req.userId, name: req.name, role: 'Viewer'));
    }
  }

  Future<void> declineRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _pendingRequests.removeWhere((r) => r.userId == userId);
  }

  Future<void> removeMember(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _members.removeWhere((m) => m.id == userId);
  }

  Future<void> changeMemberRole(String userId, String newRole) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _members.indexWhere((m) => m.id == userId);
    if (index != -1) {
      final oldMember = _members[index];
      // Do not allow changing the role of the Owner
      if (oldMember.role != 'Owner') {
        _members[index] = oldMember.copyWith(role: newRole);
      }
    }
  }

  Future<GroupEntity?> getCurrentGroup() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentGroup;
  }

  Future<List<GroupMemberEntity>> getMembers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_members);
  }

  Future<List<JoinRequestEntity>> getPendingRequests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_pendingRequests);
  }
}
