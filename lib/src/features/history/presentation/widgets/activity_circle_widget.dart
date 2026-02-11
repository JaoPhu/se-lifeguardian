import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../constants/app_stats_colors.dart';

class ActivityCircleWidget extends StatelessWidget {
  final double relaxHours;
  final double workHours;
  final double walkHours;

  const ActivityCircleWidget({
    super.key,
    required this.relaxHours,
    required this.workHours,
    required this.walkHours,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: AppStatsColors.relaxPrimary,
                  value: relaxHours,
                  title: '',
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: AppStatsColors.workPrimary,
                  value: workHours,
                  title: '',
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: AppStatsColors.walkPrimary,
                  value: walkHours,
                  title: '',
                  radius: 20,
                  showTitle: false,
                ),
                 // Remaining to fill 24h? Or just relative? 
                 // Prototype shows filled circle. Let's assume these 3 cover active time or add "Other"
                 // If we want it to look like a clock we might need 24h scale. 
                 // For now, let's just show relative proportions of these 3 as per prototype visual usually.
              ],
              centerSpaceRadius: 60,
              sectionsSpace: 0,
            ),
          ),
          const Center(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text("12", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                 SizedBox(height: 40), // Spacing
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text("9", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      SizedBox(width: 40),
                      Text("3", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                   ],
                 ),
                 SizedBox(height: 40),
                 Text("6", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
               ],
             )
          )
        ],
      ),
    );
  }
}
