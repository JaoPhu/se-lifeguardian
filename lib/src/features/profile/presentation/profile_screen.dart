import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/user_repository.dart';
import 'profile_header.dart';
import 'profile_info.dart';
import 'profile_stats.dart';
import 'medical_history.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    final List<Map<String, String>> medicalHistory = [
      {'type': 'condition', 'label': 'Medical condition', 'value': user.medicalCondition},
      {'type': 'medication', 'label': 'Current Medications', 'value': user.currentMedications},
      {'type': 'allergy_drug', 'label': 'Drug Allergies', 'value': user.drugAllergies},
      {'type': 'allergy_food', 'label': 'Food Allergies', 'value': user.foodAllergies},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(onBack: () => context.pop()), 
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileInfo(
                      name: user.name,
                      username: user.username,
                      avatarUrl: user.avatarUrl,
                      onEdit: () => context.push('/edit-profile'),
                    ),
                    ProfileStats(
                      gender: user.gender,
                      bloodType: user.bloodType,
                      age: int.tryParse(user.age) ?? 0,
                      height: int.tryParse(user.height) ?? 0,
                      weight: int.tryParse(user.weight) ?? 0,
                    ),
                    MedicalHistory(items: medicalHistory),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
