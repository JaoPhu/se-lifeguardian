import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MedicalHistory extends StatelessWidget {
  final List<Map<String, String>> items;

  const MedicalHistory({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical history',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildHistoryItem(item, theme)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, String> item, ThemeData theme) {
    IconData icon;
    switch (item['type']) {
      case 'medication':
        icon = LucideIcons.pill;
        break;
      case 'allergy_drug':
      case 'allergy_food':
        icon = LucideIcons.x;
        break;
      default:
        icon = LucideIcons.activity;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0D9488), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
                ),
                Text(
                  item['value'] ?? '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
