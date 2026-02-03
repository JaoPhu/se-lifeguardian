import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeguardian/src/common/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notification/presentation/notification_bell.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _toggleTheme() {
    final currentMode = ref.read(themeModeProvider);
    ref.read(themeModeProvider.notifier).state = 
      currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    
    // Colors
    final bgColor = isDarkMode ? const Color(0xFF111827) : const Color(0xFFFAFAFA); // gray-900 or almost white
    final cardColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white; // gray-800 or white
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937); // white or gray-800
    final subTextColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280); // gray-400 or gray-500

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 56, bottom: 32, left: 24, right: 24),
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
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const NotificationBell(color: Colors.white, whiteBorder: true),
                  ],
                ),
              ],
            ),
          ),

          // Profile Card (Overlapping)
          Transform.translate(
            offset: const Offset(0, 0), // Removed negative margin to simplify layout for now
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: GestureDetector(
                onTap: () {
                   // Navigate to profile
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=Felix'), // Mock avatar
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PhuTheOwner',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '@PhuTheOwner',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'life guardian account',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Menu Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                // Theme Toggle
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Light Mode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey.shade200),
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleTheme,
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isDarkMode ? FontWeight.bold : FontWeight.normal,
                                    color: isDarkMode ? Colors.white : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 40,
                                  height: 24,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF0D9488) : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Align(
                                    alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
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

                const SizedBox(height: 16),

                // Menu Items
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        label: 'Reset Password',
                        onTap: () => context.push('/reset-password'),
                        isDarkMode: isDarkMode,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                      ),
                      _buildDivider(isDarkMode: isDarkMode),
                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        onTap: () => context.go('/welcome'),
                        isDarkMode: isDarkMode,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isDarkMode ? Colors.white : Colors.black87),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider({required bool isDarkMode}) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
    );
  }
}
