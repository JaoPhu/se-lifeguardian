import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../data/user_repository.dart';
import '../../../common_widgets/user_avatar.dart';


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
  late TextEditingController _phoneNumberController;
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
  final _birthDateFocusNode = FocusNode();
  dynamic _imageFile; // File on mobile, XFile on web
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _emailController = TextEditingController(text: user.email);
    _phoneNumberController = TextEditingController(text: user.phoneNumber);
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
    
    _birthDateController.addListener(_onBirthDateChanged);
    _birthDateFocusNode.addListener(_onBirthDateFocusChange);
  }

  void _onBirthDateFocusChange() {
    if (!_birthDateFocusNode.hasFocus) {
      final text = _birthDateController.text.replaceAll('/', '');
      if (text.isNotEmpty && int.tryParse(text) != null) {
        _formatAndCalculateAge(text);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.removeListener(_onBirthDateChanged);
    _birthDateFocusNode.removeListener(_onBirthDateFocusChange);
    _birthDateController.dispose();
    _birthDateFocusNode.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalController.dispose();
    _medicationsController.dispose();
    _drugAllergiesController.dispose();
    _foodAllergiesController.dispose();
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
          // Default to ddMyyyy
          day = int.parse(rawDigits.substring(0, 2));
          month = int.parse(rawDigits.substring(2, 3));
          year = int.parse(rawDigits.substring(3, 7));
        }
      } else if (rawDigits.length == 6) {
        // dMyyyy
        day = int.parse(rawDigits.substring(0, 1));
        month = int.parse(rawDigits.substring(1, 2));
        year = int.parse(rawDigits.substring(2, 6));
      } else {
        return;
      }

      final DateTime birthDate = DateTime(year, month, day);
      final DateTime now = DateTime.now();
      
      // Calculate Age
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Format to dd/MM/yyyy
      final String formattedDate = '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

      if (_birthDateController.text != formattedDate) {
        _birthDateController.value = TextEditingValue(
          text: formattedDate,
          selection: TextSelection.collapsed(offset: formattedDate.length),
        );
      }
      
      _ageController.text = age.toString();
    } catch (e) {
      // Ignore parse errors
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _imageFile = pickedFile; // Store XFile directly on web
        } else {
          _imageFile = File(pickedFile.path); // Convert to File on mobile
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isUploading = true);
    try {
      final currentUser = ref.read(userProvider);
      String usernameText = _usernameController.text.trim();
      if (usernameText.startsWith('@')) {
        usernameText = usernameText.substring(1);
      }

      String avatarUrl = currentUser.avatarUrl;

      // Upload image if picked
      if (_imageFile != null) {
        debugPrint('EditProfileScreen: Starting avatar upload...');
        final newUrl = await ref.read(userRepositoryProvider).uploadAvatar(currentUser.id, _imageFile!);
        debugPrint('EditProfileScreen: Upload complete. URL: $newUrl');
        
        if (newUrl.isNotEmpty) {
          avatarUrl = newUrl;
        } else {
          throw Exception('Failed to get download URL from storage');
        }
      }

      final updatedUser = currentUser.copyWith(
        name: _nameController.text,
        username: usernameText,
        email: _emailController.text,
        phoneNumber: _phoneNumberController.text,
        avatarUrl: avatarUrl,
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

      await ref.read(userProvider.notifier).updateUser(updatedUser);
      
      if (mounted) {
        if (widget.fromRegistration) {
          context.go('/overview');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark; // Unused

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        // Use "Information" if it's a new user (empty name) or from registration flow
        title: Text(widget.fromRegistration ? 'Information' : 'Edit Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
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
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Stack(
                    children: [
                      _imageFile != null
                          ? kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: _imageFile.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: theme.dividerColor, width: 2),
                                          image: DecorationImage(
                                            image: MemoryImage(snapshot.data!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.dividerColor, width: 2),
                                      ),
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                )
                              : Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.dividerColor, width: 2),
                                    image: DecorationImage(
                                      image: FileImage(_imageFile),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                          : UserAvatar(
                              avatarUrl: user.avatarUrl,
                              radius: 50,
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
                          child: Icon(
                            _isUploading ? LucideIcons.loader : LucideIcons.image,
                            size: 16,
                            color: theme.iconTheme.color,
                          ),
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form
              _buildInputField('Name', _nameController, theme, hintText: 'Somchai Jaidee'),
              _buildInputField('Username', _usernameController, theme, hintText: 'somchai.j'),
              _buildInputField('Email', _emailController, theme, hintText: 'somchai@example.com'),
              _buildInputField('Phone Number', _phoneNumberController, theme, isNumeric: true, hintText: '0812345678'),
              
              Row(
                children: [
                  Expanded(child: _buildInputField('Birth Date', _birthDateController, theme, hintText: '01/01/1980', focusNode: _birthDateFocusNode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Age', _ageController, theme, isNumeric: true, hintText: 'Auto-calculated', readOnly: true)),
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
                      hintText: 'Select Gender',
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
                      hintText: 'Select Type',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildInputField('Height', _heightController, theme, isNumeric: true, hintText: '175')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Weight', _weightController, theme, isNumeric: true, hintText: '70')),
                ],
              ),

              _buildInputField('Medical condition', _medicalController, theme, hintText: 'Hypertension'),
              _buildInputField('Current Medications', _medicationsController, theme, hintText: 'Amlodipine 5mg'),
              _buildInputField('Drug Allergies', _drugAllergiesController, theme, hintText: 'None'),
              _buildInputField('Food Allergies', _foodAllergiesController, theme, hintText: 'Peanuts'),

              const SizedBox(height: 8),
              if (!widget.fromRegistration)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push('/change-password'),
                  icon: const Icon(LucideIcons.lock, size: 16, color: Color(0xFF0D9488)),
                  label: const Text(
                    'Change Password',
                    style: TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

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
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/overview');
                        }
                      },
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

  Widget _buildInputField(String label, TextEditingController controller, ThemeData theme, {bool isNumeric = false, String? hintText, bool readOnly = false, FocusNode? focusNode}) {
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
            focusNode: focusNode,
            readOnly: readOnly,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              hintText: hintText,
              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Icon(LucideIcons.pencil, size: 16, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
            ),
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, void Function(String?) onChanged, ThemeData theme, {String? hintText}) {
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
            initialValue: selectedValue,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true, // Fix overflow by allowing dropdown to fill width
            dropdownColor: theme.cardColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              hintText: hintText,
              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(LucideIcons.chevronDown, size: 16, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
