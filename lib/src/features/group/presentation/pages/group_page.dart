import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/group_provider.dart';
import '../widgets/group_member_card.dart';
import '../widgets/join_group_form.dart';
import '../widgets/change_group_name_dialog.dart';
import '../../../profile/data/user_repository.dart';
import '../../../notification/presentation/notification_bell.dart';
import 'package:go_router/go_router.dart';

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
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: const Text(
          'LifeGuardain',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28, // Matched with statistics screen
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          const NotificationBell(color: Colors.white),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: user.avatarUrl.isNotEmpty
                      ? Image.network(
                          user.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person_outline,
                                color: Colors.grey, size: 24);
                          },
                        )
                      : const Icon(Icons.person_outline,
                          color: Colors.grey, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.teal, // Keep background teal at top
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16), // Extra spacing below AppBar
            // Title moved from AppBar
            const Text(
              'Manage user groups',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Share health information or join to care for others.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            
            // Custom Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_outline, size: 20),
                            SizedBox(width: 8),
                            Text('My Group'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.phone_iphone, size: 20), // Placeholder icon for "Join Group" if needed
                            SizedBox(width: 8),
                            Text('Join Group'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: Container(
                color: Colors.white, // Lower half background is white
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyGroupTab(),
                    _buildJoinGroupTab(),
                  ],
                ),
              ),
            ),
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
        // Group Header (Invite Code)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'Your group invitation code\n(Invite Code)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    group.inviteCode,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.copy_outlined, color: Colors.grey.shade500, size: 28),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Send this code to the administrator to\nauthorize access to the data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
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
