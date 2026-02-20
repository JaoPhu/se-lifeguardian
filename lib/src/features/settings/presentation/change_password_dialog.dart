import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../authentication/providers/auth_providers.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authRepositoryProvider).changePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll("Exception: ", "")),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Center(
        child: Text(
          'เปลี่ยนรหัสผ่าน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Old Password
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านเดิม',
                  prefixIcon: const Icon(LucideIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่านเดิม';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านใหม่',
                  prefixIcon: const Icon(LucideIcons.key),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่านใหม่';
                  if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่านใหม่',
                  prefixIcon: const Icon(LucideIcons.checkCircle),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่านใหม่';
                  if (value != _newPasswordController.text) return 'รหัสผ่านไม่ตรงกัน';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD65D5D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ยืนยัน', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
