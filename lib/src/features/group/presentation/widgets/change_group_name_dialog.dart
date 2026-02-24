import 'package:flutter/material.dart';

class ChangeGroupNameDialog extends StatefulWidget {
  final String currentName;

  const ChangeGroupNameDialog({super.key, required this.currentName});

  @override
  State<ChangeGroupNameDialog> createState() => _ChangeGroupNameDialogState();
}

class _ChangeGroupNameDialogState extends State<ChangeGroupNameDialog> {
  late final TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _isValid = false);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Group Name'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'New Group Name',
          errorText: !_isValid ? 'Name cannot be empty' : null,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.teal),
          ),
        ),
        onChanged: (val) {
          if (!_isValid && val.trim().isNotEmpty) {
            setState(() => _isValid = true);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
