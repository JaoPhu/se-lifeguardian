class GroupEntity {
  final String id;
  final String name;
  final String inviteCode;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  GroupEntity copyWith({
    String? id,
    String? name,
    String? inviteCode,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

class GroupMemberEntity {
  final String id;
  final String name;
  final String role; // Owner / Admin / Viewer
  final String avatarUrl;

  const GroupMemberEntity({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl = '',
  });

  GroupMemberEntity copyWith({
    String? id,
    String? name,
    String? role,
    String? avatarUrl,
  }) {
    return GroupMemberEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class JoinRequestEntity {
  final String userId;
  final String name;
  final String avatarUrl;

  const JoinRequestEntity({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
  });
}
