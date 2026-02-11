import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileStats extends StatelessWidget {
  final String gender;
  final String bloodType;
  final int age;
  final int height;
  final int weight;

  const ProfileStats({
    super.key,
    required this.gender,
    required this.bloodType,
    required this.age,
    required this.height,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Gender', Icon(LucideIcons.smile, size: 24, color: theme.iconTheme.color), theme),
              _buildStatItem('Blood Type', Text(bloodType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)), theme),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Age', Text('$age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)), theme),
              _buildStatItem('Height', Text('$height', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)), theme),
              _buildStatItem('Weight', Text('$weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, Widget valueWidget, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }
}
