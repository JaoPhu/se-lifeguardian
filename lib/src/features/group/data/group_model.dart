import '../domain/group_entity.dart';

class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    required super.inviteCode,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      inviteCode: map['inviteCode'] as String,
    );
  }
}

class GroupMemberModel extends GroupMemberEntity {
  const GroupMemberModel({
    required super.id,
    required super.name,
    required super.role,
    super.avatarUrl,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }
}

class JoinRequestModel extends JoinRequestEntity {
  const JoinRequestModel({
    required super.userId,
    required super.name,
    super.avatarUrl,
  });

  factory JoinRequestModel.fromMap(Map<String, dynamic> map) {
    return JoinRequestModel(
      userId: map['userId'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }
}
