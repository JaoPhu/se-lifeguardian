import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers
  final _nameController = TextEditingController(text: 'PhuTheOwner');
  final _usernameController = TextEditingController(text: '@PhuTheOwner');
  final _emailController = TextEditingController(text: 'phutheowner@gmail.com');
  final _birthDateController = TextEditingController(text: '30/01/543'); // Mock BE date
  final _ageController = TextEditingController(text: '24');
  final _genderController = TextEditingController(text: 'Male');
  final _bloodTypeController = TextEditingController(text: 'AB');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '69');
  final _medicalConditionController = TextEditingController(text: '-');
  final _currentMedicationsController = TextEditingController(text: '-');
  final _drugAllergiesController = TextEditingController(text: '-');
  final _foodAllergiesController = TextEditingController(text: '-');
  
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 48, bottom: 8, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.grey, size: 32),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'edit profile',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                         Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : Colors.yellow.shade100,
                              shape: BoxShape.circle,
                              image: _avatarImage != null 
                                ? DecorationImage(
                                    image: FileImage(_avatarImage!),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=Felix'),
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF111827) : Colors.white, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_outlined, color: isDark ? Colors.white : Colors.grey, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildEditField('Name', _nameController, Icons.edit_note),
                  _buildEditField('Username', _usernameController, Icons.edit_note),
                  _buildEditField('Email', _emailController, Icons.edit_note),

                  Row(
                    children: [
                      Expanded(child: _buildEditField('Birth Date', _birthDateController, Icons.edit_note)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEditField('Age', _ageController, Icons.edit_note)),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(child: _buildEditField('Gender', _genderController, Icons.edit_note)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEditField('Blood Type', _bloodTypeController, Icons.edit_note)),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(child: _buildEditField('Height', _heightController, Icons.edit_note)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEditField('Weight', _weightController, Icons.edit_note)),
                    ],
                  ),

                  _buildEditField('Medical condition', _medicalConditionController, Icons.edit_note),
                  _buildEditField('Current Medications', _currentMedicationsController, Icons.edit_note),
                  _buildEditField('Drug Allergies', _drugAllergiesController, Icons.edit_note),
                  _buildEditField('Food Allergies', _foodAllergiesController, Icons.edit_note),

                  const SizedBox(height: 32),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: Color(0xFF0D9488).withValues(alpha: 0.3),
                          ),
                          child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.grey.shade100,
                            foregroundColor: const Color(0xFF0D9488),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF0D9488)
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
            border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

}
