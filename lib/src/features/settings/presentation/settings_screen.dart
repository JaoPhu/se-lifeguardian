import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../common_widgets/theme_provider.dart';
import '../../profile/data/user_repository.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../../../common_widgets/user_avatar.dart';
import '../../notification/presentation/notification_bell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
            color: const Color(0xFF0D9488),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                      onPressed: () => context.go('/overview'), 
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w700, 
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const NotificationBell(color: Colors.white, whiteBorder: true),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Profile Card
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.dividerColor, width: 1.5),
                              ),
                              child: UserAvatar(
                                avatarUrl: user.avatarUrl,
                                radius: 34,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: theme.dividerColor, width: 1.5),
                                      ),
                                    ),
                                    child: Text(
                                      user.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${user.username}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  Text(
                                    'life guardain account',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Theme Toggle Card
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                "Light Mode",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? theme.disabledColor : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 24, color: theme.dividerColor),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Dark Mode",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDarkMode ? theme.textTheme.bodyLarge?.color : theme.disabledColor,
                                      fontWeight: isDarkMode ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => ref.read(themeProvider.notifier).toggle(),
                                  child: Container(
                                    width: 40,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(milliseconds: 200),
                                      alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: isDarkMode 
                                          ? const Icon(Icons.check, size: 10, color: Color(0xFF0D9488))
                                          : const VerticalDivider(width: 1, thickness: 1.5, color: Color(0xFF94A3B8), indent: 4, endIndent: 4),
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

                    const SizedBox(height: 20),

                    // Action List Card
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [

                          // Logout
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            title: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              ref.read(authControllerProvider.notifier).logout();
                              context.go('/welcome');
                            },
                          ),
                          Divider(height: 1, indent: 20, endIndent: 20, color: theme.dividerColor),
                          // Reset Password
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            title: const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444), // Kept red as requested? Or should it be normal? Previous code had it red.
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              // Forgot password logic or navigation
                              // Assuming navigation or dialog
                            },
                          ),
                          Divider(height: 1, indent: 20, endIndent: 20, color: theme.dividerColor),
                          // Delete Account
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            title: const Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444), // Red color
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  String confirmText = '';
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return AlertDialog(
                                        title: const Text('Delete Account'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Are you sure you want to delete your account? This action cannot be undone.',
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Type "Confirm" to proceed:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              autofocus: true,
                                              onChanged: (value) {
                                                setState(() {
                                                  confirmText = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Type "Confirm"',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                contentPadding: const EdgeInsets.all(12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: confirmText.trim().toLowerCase() == 'confirm' ? () async {
                                              Navigator.of(context).pop(); // Close dialog
                                              
                                              // Show loading indicator if you want, but authController state handles it
                                              await ref.read(authControllerProvider.notifier).deleteAccount();
                                              
                                              final authState = ref.read(authControllerProvider);
                                              if (authState.hasError) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to delete: ${authState.error}'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  context.go('/welcome');
                                                }
                                              }
                                            } : null,
                                            child: Text('Delete', style: TextStyle(color: confirmText.trim().toLowerCase() == 'confirm' ? Colors.red : Colors.grey)),
                                          ),
                                        ],
                                      );
                                    }
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      "version 1.0.0",
                      style: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
