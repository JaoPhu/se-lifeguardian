import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/profile/data/user_repository.dart';
import '../../../common_widgets/user_avatar.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  // Mock Data
  String _activeTab = 'my-group'; // 'my-group' or 'join-group'
  String _joinCode = '';


  final List<Map<String, dynamic>> _members = [
    {
      'id': '1',
      'name': 'Anna',
      'role': 'Owner (You)',
      'roleType': 'Owner',
      'avatarUrl': '', // Prepared for real data
      'avatarSeed': 'Anna',
      'email': 'anna@example.com',
      'phone': '081-222-3333'
    },
    {
      'id': '2',
      'name': 'Grandson',
      'role': 'Viewer',
      'roleType': 'Viewer',
      'avatarUrl': '',
      'avatarSeed': 'Grandson',
      'email': 'grandson@example.com',
      'phone': '081-333-4444'
    },
    {
      'id': '3',
      'name': 'Doctor Somchai',
      'role': 'Admin',
      'roleType': 'Admin',
      'avatarUrl': '',
      'avatarSeed': 'Somchai',
      'email': 'somchai@example.com',
      'phone': '081-444-5555'
    },
  ];

  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': 'p1',
      'name': 'Auntie Ju',
      'avatarSeed': 'Ju'
    }
  ];




  void _handleCopyCode() {
    final user = ref.read(userProvider);
    if (user.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: user.inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied to clipboard')),
      );
    }
  }

  void _showRoleSelector(Map<String, dynamic> member) {
    if (member['roleType'] == 'Owner') return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change role for ${member['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Admin'),
              subtitle: const Text('Can manage and view all data.'),
              onTap: () {
                 // Mock update
                 Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Viewer'),
              subtitle: const Text('Can only view data.'),
              onTap: () {
                // Mock update
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewMemberProfile(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                avatarUrl: member['avatarUrl'] ?? '',
                radius: 50,
              ),
              const SizedBox(height: 16),
              Text(member['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(member['role'], style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.email, size: 20, color: Color(0xFF0D9488)),
                  const SizedBox(width: 12),
                  Text(member['email'] ?? 'No email'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone, size: 20, color: Color(0xFF0D9488)),
                  const SizedBox(width: 12),
                  Text(member['phone'] ?? 'No phone'),
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
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark; // Unused
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
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LifeGuardian',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: UserAvatar(
                            avatarUrl: user.avatarUrl,
                            radius: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage user groups',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Share health information or join to care for others.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCCFBF1), // teal-100
                  ),
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
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: _activeTab == 'my-group' ? Colors.white : Colors.grey,
                                ),
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
                                Icon(
                                  Icons.smartphone,
                                  size: 16,
                                  color: _activeTab == 'join-group' ? Colors.white : Colors.grey,
                                ),
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

          // Content
          Expanded(
            child: _activeTab == 'my-group' ? _buildMyGroupContent() : _buildJoinGroupContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyGroupContent() {
    final user = ref.watch(userProvider);
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
                onTap: _handleCopyCode,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.inviteCode ?? 'Loading...',
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
              const SizedBox(height: 16),
              Text(
                'Send this code to the administrator to authorize access to the data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Pending Requests
        if (_pendingRequests.isNotEmpty) ...[
          const Row(
            children: [
              Text('⏳', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Request to join (1)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingRequests.map((req) => _buildRequestItem(req)),
          const SizedBox(height: 32),
        ],

        // Members List
        Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Group members (${_members.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        ..._members.map((member) => _buildMemberItem(member)),
        
        // Bottom Spacer
        const SizedBox(height: 120),
      ],
    );
  }

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
                    onPressed: _joinCode.isNotEmpty ? () {} : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'เมื่อเข้าร่วมแล้ว คุณจะสามารถดูสถานะและการแจ้งเตือนจากเจ้าของกลุ่มได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        // Bottom Spacer
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> req) {
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
              UserAvatar(
                avatarUrl: req['avatarUrl'] ?? '',
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Requesting to join...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
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
                  onPressed: () {},
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
                  onPressed: () {},
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

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final user = ref.watch(userProvider);
    final roleType = member['roleType'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color roleBgColor;
    Color roleTextColor;
    Color roleBorderColor;

    switch (roleType) {
      case 'Owner':
        roleBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50;
        roleTextColor = isDark ? Colors.red.shade100 : Colors.red.shade600;
        roleBorderColor = isDark ? Colors.red.shade800 : Colors.red.shade200;
        break;
      case 'Admin':
        roleBgColor = isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50;
        roleTextColor = isDark ? Colors.orange.shade100 : Colors.orange.shade600;
        roleBorderColor = isDark ? Colors.orange.shade800 : Colors.orange.shade200;
        break;
      case 'Viewer':
      default:
        roleBgColor = isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50;
        roleTextColor = isDark ? Colors.teal.shade100 : Colors.teal.shade600;
        roleBorderColor = isDark ? Colors.teal.shade800 : Colors.teal.shade200;
        break;
    }

    return GestureDetector(
      onTap: () => _viewMemberProfile(member),
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
            UserAvatar(
              avatarUrl: (member['id'] == '1' && member['name'] == 'Anna') ? user.avatarUrl : (member['avatarUrl'] ?? ''),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    member['role'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showRoleSelector(member),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBgColor,
                  border: Border.all(color: roleBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roleType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: roleTextColor,
                  ),
                ),
              ),
            ),
            if (roleType != 'Owner') ...[
              const SizedBox(width: 8),
              const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}
