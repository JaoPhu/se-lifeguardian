import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../constants/app_stats_colors.dart';
import '../../domain/history_model.dart';

class HistoryListItem extends StatelessWidget {
  final DailyHistory history;

  const HistoryListItem({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final hasRisk = history.hasRisk;
    const riskColor = AppStatsColors.fallsPrimary; // Red/Danger color

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: hasRisk ? riskColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: hasRisk ? Border.all(color: riskColor.withValues(alpha: 0.3)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/history-detail', extra: history);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Left: Date & Total
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMM yyyy').format(history.date),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppStatsColors.defaultText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${history.totalHours.toStringAsFixed(1)}h',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Details
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatRow('Relax', history.relaxHours, AppStatsColors.relaxPrimary),
                      _buildStatRow('Work', history.workHours, AppStatsColors.workPrimary),
                      _buildStatRow('Walk', history.walkHours, AppStatsColors.walkPrimary),
                      _buildStatRow('Falls', history.fallCount.toDouble(), AppStatsColors.fallsPrimary, isInt: true),
                    ],
                  ),
                ),
                
                // Risk Icon
                if (hasRisk) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: riskColor,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color, {bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: ${isInt ? value.toInt() : value.toStringAsFixed(1)}${isInt ? '' : 'h'}",
             style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
