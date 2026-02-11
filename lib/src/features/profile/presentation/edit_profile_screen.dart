import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/user_repository.dart';


class EditProfileScreen extends ConsumerStatefulWidget {
  final bool fromRegistration;
  const EditProfileScreen({super.key, this.fromRegistration = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _medicalController;
  late TextEditingController _medicationsController;
  late TextEditingController _drugAllergiesController;
  late TextEditingController _foodAllergiesController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _emailController = TextEditingController(text: user.email);
    _birthDateController = TextEditingController(text: user.birthDate);
    _ageController = TextEditingController(text: user.age);
    _genderController = TextEditingController(text: user.gender);
    _bloodTypeController = TextEditingController(text: user.bloodType);
    _heightController = TextEditingController(text: user.height);
    _weightController = TextEditingController(text: user.weight);
    _medicalController = TextEditingController(text: user.medicalCondition);
    _medicationsController = TextEditingController(text: user.currentMedications);
    _drugAllergiesController = TextEditingController(text: user.drugAllergies);
    _foodAllergiesController = TextEditingController(text: user.foodAllergies);
  }

  void _save() {
    final currentUser = ref.read(userProvider);
    String usernameText = _usernameController.text.trim();
    if (usernameText.startsWith('@')) {
      usernameText = usernameText.substring(1);
    }

    final updatedUser = currentUser.copyWith(
      name: _nameController.text,
      username: usernameText,
      email: _emailController.text,
      birthDate: _birthDateController.text,
      age: _ageController.text,
      gender: _genderController.text,
      bloodType: _bloodTypeController.text,
      height: _heightController.text,
      weight: _weightController.text,
      medicalCondition: _medicalController.text,
      currentMedications: _medicationsController.text,
      drugAllergies: _drugAllergiesController.text,
      foodAllergies: _foodAllergiesController.text,
    );
    ref.read(userProvider.notifier).updateUser(updatedUser);
    if (widget.fromRegistration) {
      context.go('/overview');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        title: Text('edit profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(user.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        child: Icon(LucideIcons.camera, size: 16, color: theme.iconTheme.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form
              _buildInputField('Name', _nameController, theme),
              _buildInputField('Username', _usernameController, theme),
              _buildInputField('Email', _emailController, theme),
              
              Row(
                children: [
                  Expanded(child: _buildInputField('Birth Date', _birthDateController, theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Age', _ageController, theme)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Gender',
                      _genderController.text,
                      ['Male', 'Female', 'Other'],
                      (value) => setState(() => _genderController.text = value!),
                      theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      'Blood Type',
                      // Normalize O+ to O etc. for display if needed
                      _bloodTypeController.text.replaceAll('+', '').replaceAll('-', ''),
                      ['A', 'B', 'AB', 'O'],
                      (value) => setState(() => _bloodTypeController.text = value!),
                      theme,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildInputField('Height', _heightController, theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Weight', _weightController, theme)),
                ],
              ),

              _buildInputField('Medical condition', _medicalController, theme),
              _buildInputField('Current Medications', _medicationsController, theme),
              _buildInputField('Drug Allergies', _drugAllergiesController, theme),
              _buildInputField('Food Allergies', _foodAllergiesController, theme),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: BorderSide.none,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildInputField(String label, TextEditingController controller, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Icon(LucideIcons.pencil, size: 16, color: theme.iconTheme.color?.withOpacity(0.5)),
            ),
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, void Function(String?) onChanged, ThemeData theme) {
    // Ensure value is present in items or use null
    final String? selectedValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedValue,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
              );
            }).toList(),
            onChanged: onChanged,
            dropdownColor: theme.cardColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(LucideIcons.chevronDown, size: 16, color: theme.iconTheme.color?.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
