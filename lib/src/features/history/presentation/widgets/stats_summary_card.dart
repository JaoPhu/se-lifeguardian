import 'package:flutter/material.dart';

class StatsSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onTap;

  const StatsSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Icon(icon, color: iconColor, size: 36),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$label: $value",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
