import 'package:flutter/material.dart';
import '../../domain/group_entity.dart';

class GroupMemberCard extends StatelessWidget {
  final GroupMemberEntity member;
  final bool isOwnerCurrent;
  final VoidCallback? onRemove;

  const GroupMemberCard({
    super.key,
    required this.member,
    required this.isOwnerCurrent,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.teal),
        ),
      ),
      title: Text(member.name),
      subtitle: Text(member.role),
      trailing: isOwnerCurrent && member.role != 'Owner'
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemove,
            )
          : null,
    );
  }
}
