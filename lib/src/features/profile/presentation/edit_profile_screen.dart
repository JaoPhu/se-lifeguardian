import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../data/user_repository.dart';
import '../domain/user_model.dart';
import '../../../features/authentication/providers/auth_providers.dart';
import '../../../common_widgets/user_avatar.dart';


class EditProfileScreen extends ConsumerStatefulWidget {
  final bool fromRegistration;
  final String? editableUid;
  final bool medicalOnly;
  
  const EditProfileScreen({
    super.key, 
    this.fromRegistration = false,
    this.editableUid,
    this.medicalOnly = false,
  });

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
  bool _isLoadingTarget = false;
  String _targetAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
    
    // Pre-populate name from Firebase if local profile name is empty (for social sign-in)
    String initialName = user.name;
    if (initialName.isEmpty && firebaseUser?.displayName != null) {
      initialName = firebaseUser!.displayName!;
    }

    _nameController = TextEditingController(text: initialName);
    _usernameController = TextEditingController(text: user.username);
    _emailController = TextEditingController(text: user.email.isEmpty ? (firebaseUser?.email ?? '') : user.email);
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

    if (widget.editableUid != null && widget.editableUid != user.id) {
      _loadTargetUser(widget.editableUid!);
    } else {
      _targetAvatarUrl = user.avatarUrl;
    }
  }

  Future<void> _loadTargetUser(String uid) async {
    setState(() => _isLoadingTarget = true);
    try {
      final doc = await ref.read(userRepositoryProvider).getUser(uid);
      if (doc != null) {
        setState(() {
          _nameController.text = doc.name;
          _usernameController.text = doc.username;
          _emailController.text = doc.email;
          _phoneNumberController.text = doc.phoneNumber;
          _birthDateController.text = doc.birthDate;
          _ageController.text = doc.age;
          _genderController.text = doc.gender;
          _bloodTypeController.text = doc.bloodType;
          _heightController.text = doc.height;
          _weightController.text = doc.weight;
          _medicalController.text = doc.medicalCondition;
          _medicationsController.text = doc.currentMedications;
          _drugAllergiesController.text = doc.drugAllergies;
          _foodAllergiesController.text = doc.foodAllergies;
          _targetAvatarUrl = doc.avatarUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading target user for edit: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTarget = false);
    }
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

  Future<void> _showImagePickerOptions() async {
    if (widget.medicalOnly) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (_imageFile != null || _targetAvatarUrl.isNotEmpty)
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _targetAvatarUrl = '';
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (widget.medicalOnly) return; // Disallow avatar changes in medical mode
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _imageFile = pickedFile;
        });
        return;
      }

      // Crop Image
      // Crop Image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 80,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Force 1:1 output
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Move & Scale',
            toolbarColor: const Color(0xFF0D9488),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true, 
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Move & Scale',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: true, // Hide per user request
            resetButtonHidden: true, // Hide per user request
            rotateClockwiseButtonHidden: true, // Hide per user request
            cancelButtonTitle: '   Cancel   ',
            doneButtonTitle: '   Done   ',
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
           _imageFile = File(croppedFile.path); 
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneNumberController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final bloodType = _bloodTypeController.text.trim();
    String usernameText = _usernameController.text.trim();
    if (usernameText.startsWith('@')) {
      usernameText = usernameText.substring(1);
    }

    // Mandatory validation for BOTH onboarding and regular editing
    if (name.isEmpty || usernameText.isEmpty || phone.isEmpty || birthDate.isEmpty || bloodType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน (ชื่อจริง, Nickname, เบอร์โทร, วันเกิด, กรุ๊ปเลือด) เพื่อบันทึกข้อมูลครับ'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Phone number length validation (Exactly 10 digits)
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเบอร์โทรศัพท์ให้ครบ 10 หลักครับ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final currentUser = ref.read(userProvider);
      
      // Check if username is taken
      final isTaken = await ref.read(userRepositoryProvider).isUsernameTaken(usernameText, currentUser.id);
      if (isTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nickname นี้มีผู้ใช้งานแล้ว กรุณาใช้ชื่ออื่นครับ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isUploading = false);
        return;
      }

      String avatarUrl = _targetAvatarUrl;

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

      final fUser = ref.read(firebaseAuthProvider).currentUser;
      final targetId = currentUser.id.isEmpty ? (fUser?.uid ?? '') : currentUser.id;

      final updatedUser = currentUser.copyWith(
        id: targetId,
        name: name,
        username: usernameText,
        email: _emailController.text.trim(),
        phoneNumber: phone,
        avatarUrl: avatarUrl,
        birthDate: birthDate,
        age: _ageController.text,
        gender: _genderController.text,
        bloodType: bloodType,
        height: _heightController.text,
        weight: _weightController.text,
        medicalCondition: _medicalController.text,
        currentMedications: _medicationsController.text,
        drugAllergies: _drugAllergiesController.text,
        foodAllergies: _foodAllergiesController.text,
      );

      if (widget.editableUid != null && widget.editableUid != currentUser.id) {
        // We are a Caretaker editing an Owner's profile directly
        await ref.read(userRepositoryProvider).updateUserProfile(updatedUser);
      } else {
        // Updating our own profile
        await ref.read(userProvider.notifier).updateUser(updatedUser);
      }
      
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
    // Listen to user profile changes to populate fields when data arrives (e.g. after Hot Restart)
    ref.listen<User>(userProvider, (previous, next) {
      if (next.id.isNotEmpty) {
        // Only update if the field is currently empty to avoid overwriting user input
        if (_nameController.text.isEmpty && next.name.isNotEmpty) {
          _nameController.text = next.name;
        }
        if (_usernameController.text.isEmpty && next.username.isNotEmpty) {
          _usernameController.text = next.username;
        }
        if (_emailController.text.isEmpty && next.email.isNotEmpty) {
          _emailController.text = next.email;
        }
        if (_phoneNumberController.text.isEmpty && next.phoneNumber.isNotEmpty) {
          _phoneNumberController.text = next.phoneNumber;
        }
        if (_birthDateController.text.isEmpty && next.birthDate.isNotEmpty) {
          _birthDateController.text = next.birthDate;
          // Trigger age calculation
          _formatAndCalculateAge(next.birthDate.replaceAll('/', ''));
        }
        if (_genderController.text.isEmpty && next.gender.isNotEmpty) {
          _genderController.text = next.gender;
        }
        if (_bloodTypeController.text.isEmpty && next.bloodType.isNotEmpty) {
          _bloodTypeController.text = next.bloodType;
        }
        if (_heightController.text.isEmpty && next.height.isNotEmpty) {
          _heightController.text = next.height;
        }
        if (_weightController.text.isEmpty && next.weight.isNotEmpty) {
          _weightController.text = next.weight;
        }
        if (_medicalController.text.isEmpty && next.medicalCondition.isNotEmpty) {
          _medicalController.text = next.medicalCondition;
        }
        if (_medicationsController.text.isEmpty && next.currentMedications.isNotEmpty) {
          _medicationsController.text = next.currentMedications;
        }
        if (_drugAllergiesController.text.isEmpty && next.drugAllergies.isNotEmpty) {
          _drugAllergiesController.text = next.drugAllergies;
        }
        if (_foodAllergiesController.text.isEmpty && next.foodAllergies.isNotEmpty) {
          _foodAllergiesController.text = next.foodAllergies;
        }
        setState(() {});
      }
    });

    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark; // Unused

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.fromRegistration
            ? null // No back button during mandatory onboarding
            : IconButton(
                icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
                onPressed: () => context.pop(),
              ),
        // Use "Information" if it's a new user (empty name) or from registration flow
        title: Text(
          widget.fromRegistration ? 'Information' : 'Edit Profile',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                  onTap: _isUploading ? null : _showImagePickerOptions,
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
                              avatarUrl: _targetAvatarUrl,
                              radius: 50,
                            ),
                      if (!widget.medicalOnly)
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

              if (widget.fromRegistration)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'กรุณากรอกข้อมูลสำคัญให้ครบถ้วนก่อนเริ่มต้นใช้งาน เพื่อความปลอดภัยและประสิทธิภาพสูงสุดของระบบครับ',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              _buildInputField('Name and Surname', _nameController, theme, hintText: 'Somchai Jaidee', isRequired: true, readOnly: widget.medicalOnly),
              _buildInputField('Nickname', _usernameController, theme, hintText: 'somchai.j', isRequired: true, readOnly: widget.medicalOnly),
              _buildInputField('Email', _emailController, theme, hintText: 'somchai@example.com', readOnly: true),
              _buildInputField('Phone Number', _phoneNumberController, theme, isNumeric: true, hintText: '0812345678', isRequired: true, readOnly: widget.medicalOnly),
              
              Row(
                children: [
                   Expanded(child: _buildInputField('Birth Date', _birthDateController, theme, hintText: '01/01/1980', focusNode: widget.medicalOnly ? null : _birthDateFocusNode, isRequired: true, readOnly: widget.medicalOnly)),
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
                      widget.medicalOnly ? null : (value) => setState(() => _genderController.text = value!),
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
                      widget.medicalOnly ? null : (value) => setState(() => _bloodTypeController.text = value!),
                      theme,
                      hintText: 'Select Type',
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildInputField('Height', _heightController, theme, isNumeric: true, hintText: '175', readOnly: widget.medicalOnly)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Weight', _weightController, theme, isNumeric: true, hintText: '70', readOnly: widget.medicalOnly)),
                ],
              ),

              _buildInputField('Medical condition', _medicalController, theme, hintText: 'Hypertension'),
              _buildInputField('Current Medications', _medicationsController, theme, hintText: 'Amlodipine 5mg'),
              _buildInputField('Drug Allergies', _drugAllergiesController, theme, hintText: 'None'),
              _buildInputField('Food Allergies', _foodAllergiesController, theme, hintText: 'Peanuts'),

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
                  if (!widget.fromRegistration) ...[
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, ThemeData theme, {bool isNumeric = false, String? hintText, bool readOnly = false, FocusNode? focusNode, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            inputFormatters: const [], // Removed all restrictive formatters
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
              suffixIcon: readOnly ? null : Icon(LucideIcons.pencil, size: 16, color: theme.iconTheme.color?.withValues(alpha: 0.5)),
            ),
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, void Function(String?)? onChanged, ThemeData theme, {String? hintText, bool isRequired = false}) {
    // Ensure value is present in items or use null
    final String? selectedValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
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
