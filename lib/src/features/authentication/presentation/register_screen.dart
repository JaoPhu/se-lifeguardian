import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/social_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ ใช้ controller แทน AuthService
import 'package:lifeguardian/src/features/authentication/controllers/auth_controller.dart';
import 'package:lifeguardian/src/features/profile/data/user_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeTerms = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _onAuthError(Object e) {
    final err = e.toString().toLowerCase();
    if (err.contains('account-already-exists') || 
        err.contains('email-already-in-use') || 
        err.contains('email already registered')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('บัญชีนี้มีอยู่ในระบบแล้ว'),
            ],
          ),
          content: const Text(
            'อีเมลนี้ได้รับการลงทะเบียนแล้ว กรุณาเข้าสู่ระบบเพื่อใช้งาน',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pushReplacement('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('เข้าสู่ระบบ'),
            ),
          ],
        ),
      );
    } else {
      _showSnack(e.toString());
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
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
                'Create account',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Sign up to continue',
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
                hintText: 'Create password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 20),
              AuthTextField(
                label: 'Confirm password',
                hintText: 'Re-enter password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _agreeTerms = value ?? false;
                              });
                            },
                      activeColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to ',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Terms',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Conditions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
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
                          final confirm =
                              _confirmPasswordController.text.trim();

                          if (email.isEmpty ||
                              password.isEmpty ||
                              confirm.isEmpty) {
                            _showSnack('กรอกข้อมูลให้ครบทุกช่องก่อนนะ');
                            return;
                          }
                          if (!_agreeTerms) {
                            _showSnack('กรุณาติ๊กยอมรับ Terms & Conditions');
                            return;
                          }
                          if (password != confirm) {
                            _showSnack('รหัสผ่านไม่ตรงกัน');
                            return;
                          }

                          await ref
                              .read(authControllerProvider.notifier)
                              .register(email, password);

                          final s = ref.read(authControllerProvider);
                          s.whenOrNull(
                            error: (e, st) => _onAuthError(e),
                            data: (_) {
                              // Direct to information page after registration
                              context.pushReplacement('/edit-profile', extra: {'fromRegistration': true});
                            },
                          );
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Create account',
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

                        await ref
                            .read(authControllerProvider.notifier)
                            .registerWithGoogle();

                        final s = ref.read(authControllerProvider);
                        s.whenOrNull(
                          error: (e, st) => _onAuthError(e),
                          data: (_) => context.pushReplacement('/edit-profile', extra: {'fromRegistration': true}),
                        );
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

                          await ref
                              .read(authControllerProvider.notifier)
                              .registerWithApple();

                          final s = ref.read(authControllerProvider);
                          s.whenOrNull(
                            error: (e, st) => _onAuthError(e),
                            data: (_) => context.pushReplacement('/edit-profile', extra: {'fromRegistration': true}),
                          );
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
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context.pushReplacement('/login'),
                    child: Text(
                      'Login',
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
