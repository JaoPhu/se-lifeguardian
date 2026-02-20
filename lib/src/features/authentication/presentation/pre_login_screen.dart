import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PreLoginScreen extends StatelessWidget {
  const PreLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => context.go('/welcome'),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              shape: const CircleBorder(),
              side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Title Section
            const Text(
              'LifeGuardian',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9488), // Teal
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Login or signup to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const Spacer(),

            // Illustration Placeholder
            Image.asset(
              'assets/images/success_cloud.png',
              height: isSmallScreen ? 240 : 300,
              fit: BoxFit.contain,
            ),

            const Spacer(),

            // Bottom Actions
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, isSmallScreen ? 48 : 80),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Already have an account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
