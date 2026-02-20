import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/social_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ controller
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
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender = 'Male';
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

  void _onBirthDateChanged() {
    final String text = _birthDateController.text.replaceAll('/', '');
    if (text.length == 8 && int.tryParse(text) != null) {
      _formatAndCalculateAge(text);
    }
  }

  void _formatAndCalculateAge(String rawDigits) {
    try {
      int day, month, year;

      if (rawDigits.length == 8) {
        // ddMMyyyy
        day = int.parse(rawDigits.substring(0, 2));
        month = int.parse(rawDigits.substring(2, 4));
        year = int.parse(rawDigits.substring(4, 8));
      } else if (rawDigits.length == 7) {
        // dMMyyyy or ddMyyyy
        final d2 = int.parse(rawDigits.substring(0, 2));
        if (d2 > 31) {
          day = int.parse(rawDigits.substring(0, 1));
          month = int.parse(rawDigits.substring(1, 3));
          year = int.parse(rawDigits.substring(3, 7));
        } else {
          final m2 = int.parse(rawDigits.substring(1, 3));
          if (m2 > 12) {
            day = int.parse(rawDigits.substring(0, 2));
            month = int.parse(rawDigits.substring(2, 3));
            year = int.parse(rawDigits.substring(3, 7));
          } else {
            day = int.parse(rawDigits.substring(0, 2));
            month = int.parse(rawDigits.substring(2, 3));
            year = int.parse(rawDigits.substring(3, 7));
          }
        }
      } else if (rawDigits.length == 6) {
        // dMyyyy
        day = int.parse(rawDigits.substring(0, 1));
        month = int.parse(rawDigits.substring(1, 2));
        year = int.parse(rawDigits.substring(2, 6));
      } else {
        return;
      }

      if (month < 1 || month > 12 || day < 1 || day > 31) return;

      final DateTime birthDate = DateTime(year, month, day);
      final DateTime now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      final String formattedDate =
          '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

      if (_birthDateController.text != formattedDate) {
        _birthDateController.value = TextEditingValue(
          text: formattedDate,
          selection: TextSelection.collapsed(offset: formattedDate.length),
        );
      }
      _ageController.text = age.toString();
    } catch (_) {
      // ignore
    }
  }

  void _onAuthError(Object e) {
    final err = e.toString().toLowerCase();
    if (err.contains('account-already-exists') ||
        err.contains('email-already-in-use') ||
        err.contains('email already registered')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text(
              'บัญชีนี้มีอยู่ในระบบแล้ว',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          content: const Text(
            'อีเมลนี้ได้รับการลงทะเบียนแล้ว กรุณาเข้าสู่ระบบเพื่อใช้งาน',
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
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('เข้าสู่ระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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

Future<void> _ensureUserDocAfterAuth() async {
  await ref.read(userRepositoryProvider).ensureUserDoc(
    displayName: _nameController.text,
    gender: _gender,
    birthDate: _birthDateController.text,
    age: _ageController.text,
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
            onPressed: () => context.go('/pre-login'),
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

                          // ✅ 1) Register ก่อน (ให้ได้ uid)
                          await ref
                              .read(authControllerProvider.notifier)
                              .register(email, password);

                          // ✅ 2) เช็ค state หลัง register
                          final s = ref.read(authControllerProvider);
                          if (s.hasError) {
                            _onAuthError(s.error!);
                            return;
                          }

                          // ✅ 3) สร้าง/อัปเดต users/{uid} ใน Firestore (แก้ Unknown)
                          await ref.read(userRepositoryProvider).ensureUserDoc(
                                displayName: _nameController.text,
                                gender: _gender,
                                birthDate: _birthDateController.text,
                                age: _ageController
                                    .text, // ✅ ส่งเป็น String ให้ตรงกับ repo
                              );

                          if (!context.mounted) return;

                          // ✅ 4) ไปหน้า edit-profile
                          context.pushReplacement(
                            '/edit-profile',
                            extra: {'fromRegistration': true},
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
                        if (s.hasError) {
                          _onAuthError(s.error!);
                          return;
                        }

                        await _ensureUserDocAfterAuth();

                        if (!context.mounted) return;
                        context.pushReplacement('/edit-profile',
                            extra: {'fromRegistration': true});
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
                          if (s.hasError) {
                            _onAuthError(s.error!);
                            return;
                          }

                          await _ensureUserDocAfterAuth();

                          if (!context.mounted) return;
                          context.pushReplacement('/edit-profile',
                              extra: {'fromRegistration': true});
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
