import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/weekly_stats_model.dart';

import '../../../../constants/app_stats_colors.dart';

class WeeklyChartWidget extends StatelessWidget {
  final WeeklyStatsModel weeklyStats;

  const WeeklyChartWidget({super.key, required this.weeklyStats});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12,
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'Mon'; break;
                    case 1: text = 'Tue'; break;
                    case 2: text = 'Wed'; break;
                    case 3: text = 'Thu'; break;
                    case 4: text = 'Fri'; break;
                    case 5: text = 'Sat'; break;
                    case 6: text = 'Sun'; break;
                    default: text = '';
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: weeklyStats.dailyStats.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            // Stacked bar logic
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.relaxHours + data.workHours + data.walkHours,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: [
                    BarChartRodStackItem(0, data.relaxHours, AppStatsColors.relaxPrimary),
                    BarChartRodStackItem(data.relaxHours, data.relaxHours + data.workHours, AppStatsColors.workPrimary),
                    BarChartRodStackItem(data.relaxHours + data.workHours, data.relaxHours + data.workHours + data.walkHours, AppStatsColors.walkPrimary),
                     if (data.falls > 0)
                        BarChartRodStackItem(data.relaxHours + data.workHours + data.walkHours, data.relaxHours + data.workHours + data.walkHours + 0.5, AppStatsColors.fallsPrimary),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
