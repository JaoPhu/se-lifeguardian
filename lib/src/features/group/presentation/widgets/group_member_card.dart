import 'package:flutter/material.dart';
import '../../domain/group_entity.dart';

class GroupMemberCard extends StatelessWidget {
  final GroupMemberEntity member;
  final bool isOwnerCurrent;
  final VoidCallback? onRemove;
  final ValueChanged<String>? onChangeRole;

  const GroupMemberCard({
    super.key,
    required this.member,
    required this.isOwnerCurrent,
    this.onRemove,
    this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    Widget trailingWidget;

    if (member.role == 'Owner') {
      trailingWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Owner',
          style: TextStyle(
            color: Colors.red.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      if (isOwnerCurrent) {
        trailingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: member.role == 'Admin' 
                    ? Colors.orange.shade50 
                    : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: member.role,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  style: TextStyle(
                    color: member.role == 'Admin'
                        ? Colors.orange.shade800
                        : Colors.teal.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null && onChangeRole != null) {
                      onChangeRole!(newValue);
                    }
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return <String>['Admin', 'Viewer'].map((String value) {
                      return Center(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: member.role == 'Admin'
                                ? Colors.orange.shade800
                                : Colors.teal.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: <String>['Admin', 'Viewer']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          if (member.role == value) ...[
                            const Icon(Icons.check, color: Colors.black, size: 18),
                            const SizedBox(width: 8),
                          ] else ...[
                            const SizedBox(width: 26),
                          ],
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onRemove,
            ),
          ],
        );
      } else {
        trailingWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: member.role == 'Admin' 
                ? Colors.orange.shade50 
                : Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            member.role,
            style: TextStyle(
              color: member.role == 'Admin'
                  ? Colors.orange.shade800
                  : Colors.teal.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.circle, color: Colors.teal, size: 10),
        minLeadingWidth: 10,
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          member.role,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: trailingWidget,
      ),
    );
  }
}
