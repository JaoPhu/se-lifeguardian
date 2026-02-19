import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeguardian/src/features/authentication/data/email_service.dart';
import 'package:lifeguardian/src/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:lifeguardian/src/features/authentication/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check if user exists
      final authRepo = ref.read(authRepositoryProvider);
      final exists = await authRepo.checkUserExists(email);

      if (!exists) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Not Found'),
            content: const Text('There is no account associated with this email address. Please check your email or register a new account.'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('OK', style: TextStyle(color: Color(0xFF0D9488))),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Generate and Send OTP
      if (!mounted) return;
      
      final otp = EmailService.generateOTP();
      final success = await EmailService.sendOTP(email, otp);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งรหัสยืนยันไปยังอีเมลของคุณแล้ว')),
        );
        context.push('/otp-verification', extra: {
          'email': email,
        });
      } else {
        // Fallback option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ส่งรหัสไม่สำเร็จ'),
            content: const Text('ไม่สามารถส่งรหัส OTP ได้ คุณต้องการรับลิ้งค์รีเซ็ตรหัสผ่านแทนหรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  context.pop();
                  _sendResetLink(email);
                },
                child: const Text('ส่งลิ้งค์', style: TextStyle(color: Color(0xFF0D9488))),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendResetLink(String email) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email')),
      );
      context.pop(); // Go back to login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
              shape: const CircleBorder(),
              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Forgot password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Mail Icon Placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.mark_email_read_outlined, size: 60, color: isDark ? Colors.grey.shade300 : const Color(0xFF111827)),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Verify Email',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your email or number then we will send you a code to reset your password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),
              AuthTextField(
                label: 'Email',
                hintText: 'Enter your gmail',
                prefixIcon: Icons.mail_outline,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
