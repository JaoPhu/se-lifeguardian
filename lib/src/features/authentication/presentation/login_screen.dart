import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/social_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ controller
import 'package:lifeguardian/src/features/authentication/controllers/auth_controller.dart';
import 'package:lifeguardian/src/features/profile/data/user_repository.dart'; // ✅ ใช้ ensureUserDoc()

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _keepLoggedIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthError(Object e) {
    final err = e.toString().toLowerCase();
    
    // 🔥 Firebase often returns 'invalid-credential' for both wrong password AND non-existent users
    // to prevent email enumeration. We treat it as a "maybe you need to register" case
    // if it's a fresh wipe test.
    if (err.contains('user-not-found') ||
        err.contains('no user record') ||
        err.contains('user not found') ||
        err.contains('invalid-credential')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text(
              'ไม่พบข้อมูลบัญชี',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          content: const Text(
            'ไม่พบอีเมลนี้ในระบบ หรือบัญชีของคุณอาจถูกลบไปแล้ว (หากพึ่งล้างข้อมูลระบบ กรุณาสมัครสมาชิกใหม่ครับ)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD65D5D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/register');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('สมัครสมาชิก', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (err.contains('wrong-password') || err.contains('invalid-credential')) {
      _showSnack('รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง');
    } else {
      _showSnack(e.toString());
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _afterLoginEnsureUserDoc() async {
    // ✅ หลัง login สำเร็จ ให้สร้าง/อัปเดต users/{uid} เสมอ (กัน Unknown)
    await ref.read(userRepositoryProvider).ensureUserDoc();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => context.go('/pre-login'),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
              shape: const CircleBorder(),
              side: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Login account',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              AuthTextField(
                label: 'Email',
                hintText: 'example@gmail.com',
                prefixIcon: Icons.mail_outline,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              AuthTextField(
                label: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _keepLoggedIn,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _keepLoggedIn = value ?? false;
                                  });
                                },
                          activeColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Keep me logged in',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey.shade400 : const Color(0xFF374151),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            _showSnack('กรอกอีเมลและรหัสผ่านก่อนนะ');
                            return;
                          }

                          // ✅ 1) Login
                          await ref.read(authControllerProvider.notifier).login(email, password);

                          // ✅ 2) เช็ค state หลัง login
                          final s = ref.read(authControllerProvider);
                          if (s.hasError) {
                            _onAuthError(s.error!);
                            return;
                          }

                          // ✅ 3) สร้าง users/{uid} (กรณี login ด้วย Google/Apple/เก่าๆแล้วไม่มี doc)
                          await _afterLoginEnsureUserDoc();

                          if (!context.mounted) return;
                          context.go('/overview');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or sign up with',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SocialButton(
                      label: 'Google',
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        width: 24,
                      ),
                      onPressed: () async {
                        if (isLoading) return;

                        await ref.read(authControllerProvider.notifier).loginWithGoogle();

                        final s = ref.read(authControllerProvider);
                        if (s.hasError) {
                          _onAuthError(s.error!);
                          return;
                        }

                        await _afterLoginEnsureUserDoc();

                        if (!context.mounted) return;
                        context.go('/overview');
                      },
                    ),
                  ),
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: SocialButton(
                        label: 'Apple',
                        icon: Icon(
                          Icons.apple,
                          color: isDark ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        onPressed: () async {
                          if (isLoading) return;

                          await ref.read(authControllerProvider.notifier).loginWithApple();

                          final s = ref.read(authControllerProvider);
                          if (s.hasError) {
                            _onAuthError(s.error!);
                            return;
                          }

                          await _afterLoginEnsureUserDoc();

                          if (!context.mounted) return;
                          context.go('/overview');
                        },
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () => context.go('/register'),
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
