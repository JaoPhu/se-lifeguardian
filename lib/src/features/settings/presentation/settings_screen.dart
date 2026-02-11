import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../common_widgets/theme_provider.dart';
import '../../profile/data/user_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final user = ref.watch(userProvider);
    
    final bgColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF374151);
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
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
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.bell, color: Colors.white, size: 28),
                      onPressed: () => context.push('/notifications'),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    ),
                  ],
                ),
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
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.shade200, width: 1.5),
                              ),
                              child: CircleAvatar(
                                radius: 34,
                                backgroundImage: NetworkImage(user.avatarUrl),
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
                                        bottom: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFFD1D5DB), width: 1.5),
                                      ),
                                    ),
                                    child: Text(
                                      user.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${user.username}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    'life guardain account',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
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
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: borderColor),
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
                                  color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 24, color: isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Dark Mode",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDarkMode ? Colors.white : Colors.grey.shade400,
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
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [

                          // Reset Password
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            title: const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {},
                          ),
                          Divider(height: 1, indent: 20, endIndent: 20, color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFE5E7EB)),
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
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      "version 1.0.0",
                      style: TextStyle(
                        color: Colors.grey.shade400,
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
