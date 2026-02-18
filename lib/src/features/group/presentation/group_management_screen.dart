import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/profile/data/user_repository.dart';
import '../../../common_widgets/user_avatar.dart';

// ✅ เพิ่ม: import providers + domain models ของ group
import '../providers/group_providers.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';
import '../domain/join_request.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  String _activeTab = 'my-group'; // 'my-group' or 'join-group'
  String _joinCode = '';

  // ---------- Helpers ----------
  String _roleLabel(String role) {
    final r = role.toLowerCase();
    if (r == 'owner') return 'Owner';
    if (r == 'admin') return 'Admin';
    return 'Viewer';
  }

  Color _roleBg(BuildContext context, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = role.toLowerCase();
    if (r == 'owner') return isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50;
    if (r == 'admin') return isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50;
    return isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50;
  }

  Color _roleText(BuildContext context, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = role.toLowerCase();
    if (r == 'owner') return isDark ? Colors.red.shade100 : Colors.red.shade600;
    if (r == 'admin') return isDark ? Colors.orange.shade100 : Colors.orange.shade600;
    return isDark ? Colors.teal.shade100 : Colors.teal.shade600;
  }

  Color _roleBorder(BuildContext context, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = role.toLowerCase();
    if (r == 'owner') return isDark ? Colors.red.shade800 : Colors.red.shade200;
    if (r == 'admin') return isDark ? Colors.orange.shade800 : Colors.orange.shade200;
    return isDark ? Colors.teal.shade800 : Colors.teal.shade200;
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  Future<void> _createGroupDialog() async {
    final controller = TextEditingController(text: 'My Group');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Group name',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(groupRepoProvider).createOwnerGroup(name: controller.text.trim().isEmpty ? 'My Group' : controller.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create group failed: $e')),
      );
    }
  }

  Future<void> _joinByCode() async {
    try {
      await ref.read(groupRepoProvider).requestJoinByCode(_joinCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent!')),
      );
      setState(() => _joinCode = '');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join failed: $e')),
      );
    }
  }

  void _showRoleSelector({
    required String groupId,
    required GroupMember member,
  }) {
    final role = member.role.toLowerCase();
    if (role == 'owner') return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change role for ${member.displayName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Admin'),
                subtitle: const Text('Can manage and view all data.'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(groupRepoProvider).changeRole(
                      groupId: groupId,
                      targetUid: member.uid,
                      role: 'admin',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Change role failed: $e')),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Viewer'),
                subtitle: const Text('Can only view data.'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(groupRepoProvider).changeRole(
                      groupId: groupId,
                      targetUid: member.uid,
                      role: 'viewer',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Change role failed: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewMemberProfile({
    required GroupMember member,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(member.uid).get(),
            builder: (context, snap) {
              final data = snap.data?.data() ?? {};
              final email = (data['email'] as String?) ?? '-';
              final phone = (data['phone'] as String?) ?? '-';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    avatarUrl: member.avatarUrl,
                    radius: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(member.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_roleLabel(member.role), style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 20, color: Color(0xFF0D9488)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(email)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Color(0xFF0D9488)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(phone)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.fingerprint, size: 20, color: Color(0xFF0D9488)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(member.uid)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove({
    required String groupId,
    required GroupMember member,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.displayName} from this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(groupRepoProvider).removeMember(
        groupId: groupId,
        targetUid: member.uid,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 56, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LifeGuardian',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: UserAvatar(avatarUrl: user.avatarUrl, radius: 18),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage user groups',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Share health information or join to care for others.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFCCFBF1)),
                ),
                const SizedBox(height: 24),

                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 'my-group'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _activeTab == 'my-group' ? const Color(0xFF0D9488) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group, size: 16, color: _activeTab == 'my-group' ? Colors.white : Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'My Group',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _activeTab == 'my-group' ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 'join-group'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _activeTab == 'join-group' ? const Color(0xFF0D9488) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.smartphone, size: 16, color: _activeTab == 'join-group' ? Colors.white : Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Join Group',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _activeTab == 'join-group' ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 'my-group' ? _buildMyGroupContent() : _buildJoinGroupContent(),
          ),
        ],
      ),
    );
  }

  // ---------- MY GROUP ----------
  Widget _buildMyGroupContent() {
    final ownerGroupAsync = ref.watch(ownerGroupProvider);

    return ownerGroupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (Group? group) {
        if (group == null) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'You don’t have an owner group yet.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _createGroupDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Create Group'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          );
        }

        final membersAsync = ref.watch(groupMembersProvider(group.id));
        final reqAsync = ref.watch(joinRequestsProvider(group.id));

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Invite Code Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  Text(
                    'Your group invitation code (Invite Code)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _copyToClipboard(group.inviteCode),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          group.inviteCode,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await ref.read(groupRepoProvider).regenerateInviteCode(group.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code regenerated')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Regenerate failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF0D9488)),
                      label: const Text('Regenerate Code'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Send this code to authorize access to the data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Pending Requests
            reqAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Requests error: $e'),
              data: (List<JoinRequest> reqs) {
                if (reqs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('⏳', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Request to join (${reqs.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...reqs.map((r) => _buildRequestCard(groupId: group.id, req: r)),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            // Members List
            Row(
              children: [
                const Text('👑', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                membersAsync.when(
                  loading: () => const Text('Group members (...)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  error: (e, _) => Text('Group members (error)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  data: (members) => Text(
                    'Group members (${members.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Members error: $e'),
              data: (List<GroupMember> members) {
                return Column(
                  children: members
                      .map((m) => _buildMemberCard(
                            groupId: group.id,
                            member: m,
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 120),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard({
    required String groupId,
    required JoinRequest req,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(avatarUrl: req.avatarUrl, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text('Requesting to join...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(groupRepoProvider).approveRequest(
                            groupId: groupId,
                            targetUid: req.uid,
                            role: 'viewer',
                          );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Approve failed: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(groupRepoProvider).declineRequest(
                            groupId: groupId,
                            targetUid: req.uid,
                          );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Decline failed: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade100,
                    foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    elevation: 0,
                    side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard({
    required String groupId,
    required GroupMember member,
  }) {
    final roleType = _roleLabel(member.role);

    final roleBgColor = _roleBg(context, member.role);
    final roleTextColor = _roleText(context, member.role);
    final roleBorderColor = _roleBorder(context, member.role);

    return GestureDetector(
      onTap: () => _viewMemberProfile(member: member),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            UserAvatar(avatarUrl: member.avatarUrl, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    roleType,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showRoleSelector(groupId: groupId, member: member),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBgColor,
                  border: Border.all(color: roleBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roleType,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleTextColor),
                ),
              ),
            ),
            if (roleType != 'Owner') ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmRemove(groupId: groupId, member: member),
                child: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- JOIN GROUP ----------
  Widget _buildJoinGroupContent() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter Invitation Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _joinCode = value),
                    decoration: InputDecoration(
                      hintText: 'Ex. LG-9821',
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0D9488)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _joinCode.trim().isNotEmpty ? _joinByCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Join', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'เมื่อเข้าร่วมแล้ว คุณจะสามารถดูสถานะและการแจ้งเตือนจากเจ้าของกลุ่มได้',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}
