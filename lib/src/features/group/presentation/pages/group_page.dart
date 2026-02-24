import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/group_provider.dart';
import '../widgets/group_member_card.dart';
import '../widgets/join_group_form.dart';
import '../widgets/change_group_name_dialog.dart';

class GroupPage extends ConsumerStatefulWidget {
  const GroupPage({super.key});

  @override
  ConsumerState<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends ConsumerState<GroupPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes for error messages mapped to snackbars
    ref.listen<GroupState>(groupProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Group'),
            Tab(text: 'Join Group'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyGroupTab(),
            _buildJoinGroupTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupTab() {
    final state = ref.watch(groupProvider);

    return RefreshIndicator(
      color: Colors.teal,
      onRefresh: () => ref.read(groupProvider.notifier).refreshGroupData(),
      child: state.isLoading && state.currentGroup == null
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (state.currentGroup == null)
                  _buildEmptyGroupState()
                else
                  _buildGroupDetails(state),
              ],
            ),
    );
  }

  Widget _buildEmptyGroupState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.group_off, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          "You don't have a group yet.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            ref.read(groupProvider.notifier).createGroup("My New Group");
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('Create New Group'),
        ),
      ],
    );
  }

  Widget _buildGroupDetails(GroupState state) {
    final group = state.currentGroup!;
    // In our mock, the first member is usually the owner or we determine by role
    final bool isOwner = state.members.any((m) => m.name.contains('(Me)') && m.role == 'Owner');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Code: ', style: TextStyle(color: Colors.grey)),
                          Text(
                            group.inviteCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.teal),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: group.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard!')),
                        );
                      },
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        onPressed: () async {
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) =>
                                ChangeGroupNameDialog(currentName: group.name),
                          );
                          if (newName != null && newName.isNotEmpty) {
                            ref
                                .read(groupProvider.notifier)
                                .changeGroupName(newName);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Members List
        Text(
          'Members (${state.members.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...state.members.map((m) => GroupMemberCard(
              member: m,
              isOwnerCurrent: isOwner,
              onRemove: () =>
                  ref.read(groupProvider.notifier).removeMember(m.id),
              onChangeRole: (newRole) =>
                  ref.read(groupProvider.notifier).changeMemberRole(m.id, newRole),
            )),
        const SizedBox(height: 24),

        // Pending Requests
        if (isOwner && state.pendingRequests.isNotEmpty) ...[
          const Text(
            'Pending Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...state.pendingRequests.map((req) => Card(
                elevation: 0,
                color: Colors.teal.shade50.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.tealAccent.shade100,
                    child: const Icon(Icons.person, color: Colors.black87),
                  ),
                  title: Text(req.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        onPressed: () => ref
                            .read(groupProvider.notifier)
                            .approveRequest(req.userId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                        onPressed: () => ref
                            .read(groupProvider.notifier)
                            .declineRequest(req.userId),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildJoinGroupTab() {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: JoinGroupForm(),
    );
  }
}
