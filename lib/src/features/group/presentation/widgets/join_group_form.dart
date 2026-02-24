import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/group_provider.dart';

class JoinGroupForm extends ConsumerStatefulWidget {
  const JoinGroupForm({super.key});

  @override
  ConsumerState<JoinGroupForm> createState() => _JoinGroupFormState();
}

class _JoinGroupFormState extends ConsumerState<JoinGroupForm> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {
        _hasInput = _codeController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text.trim();
      await ref.read(groupProvider.notifier).joinGroup(code);
      if (mounted) {
        final state = ref.read(groupProvider);
        if (state.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully sent join request!')),
          );
          _codeController.clear();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join an Existing Group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invitation Code',
                hintText: 'e.g. LG-1234',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a code';
                }
                if (!RegExp(r'^LG-\d{4}$').hasMatch(value.trim())) {
                  return 'Format must be LG-XXXX';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.teal;
                    }
                    return _hasInput ? Colors.teal : Colors.grey.shade400;
                  },
                ),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Join Group',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              'เมื่อเข้าร่วมแล้ว คุณจะสามารถดูสถานะและการแจ้ง\nเตือนจากเจ้าของกลุ่มได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
