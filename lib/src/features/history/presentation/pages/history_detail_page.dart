import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../domain/history_model.dart';
import '../../../../constants/app_stats_colors.dart';

class HistoryDetailPage extends StatelessWidget {
  final DailyHistory history;

  const HistoryDetailPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('d MMMM yyyy').format(history.date),
           style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D9488),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard("Total Activity", "${history.totalHours.toStringAsFixed(1)} h", Icons.access_time, Colors.blue),
            const SizedBox(height: 16),
            _buildDetailCard("Relax", "${history.relaxHours} h", Icons.weekend, AppStatsColors.relaxPrimary),
            const SizedBox(height: 16),
            _buildDetailCard("Work", "${history.workHours} h", Icons.work, AppStatsColors.workPrimary),
            const SizedBox(height: 16),
            _buildDetailCard("Walk", "${history.walkHours} h", Icons.directions_walk, AppStatsColors.walkPrimary),
            const SizedBox(height: 16),
            _buildDetailCard("Falls", "${history.fallCount} times", Icons.warning_amber_rounded, AppStatsColors.fallsPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
