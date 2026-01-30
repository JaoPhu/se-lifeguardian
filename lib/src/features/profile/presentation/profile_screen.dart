import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user data
    const user = {
      'name': 'PhuTheOwner',
      'username': '@PhuTheOwner',
      'avatarUrl': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
      'gender': 'Male',
      'bloodType': 'AB',
      'age': '24',
      'height': '175',
      'weight': '69',
      'medicalCondition': '-',
      'currentMedications': '-',
      'drugAllergies': '-',
      'foodAllergies': '-',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 56),
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 80),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Avatar
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 8),
                image: const DecorationImage(
                  image: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=Felix'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Name & Username
            const Text(
              'hewkai',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const Text(
              '@lnwhewkaimak',
              style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
            ),
            
            const SizedBox(height: 24),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.push('/edit-profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProfileStatColumn(context, 'Gender', 'Male', Icons.person_outline),
                      _buildProfileStatColumn(context, 'Blood Type', 'O', null, isTextLarge: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProfileStatColumn(context, 'Age', '21', null, isTextLarge: true),
                      _buildProfileStatColumn(context, 'Height', '169', null, isTextLarge: true),
                      _buildProfileStatColumn(context, 'Weight', '68', null, isTextLarge: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Medical History Container
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(40),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical history',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF0D9488)
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMedicalItem('Medical condition', '-', Icons.health_and_safety_outlined),
                  _buildMedicalItem('Current Medications', '-', Icons.medication_outlined),
                  _buildMedicalItem('Drug Allergies', '-', Icons.close),
                  _buildMedicalItem('Food Allergies', '-', Icons.close),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatColumn(BuildContext context, String label, String value, IconData? icon, {bool isTextLarge = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        if (icon != null)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: isTextLarge ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
      ],
    );
  }

  Widget _buildMedicalItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0D9488), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
