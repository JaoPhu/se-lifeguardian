import 'daily_stats_model.dart';

class WeeklyStatsModel {
  final List<DailyStatsModel> dailyStats;

  WeeklyStatsModel({required this.dailyStats});

  double get totalRelaxHours => dailyStats.fold(0, (sum, item) => sum + item.relaxHours);
  double get totalWorkHours => dailyStats.fold(0, (sum, item) => sum + item.workHours);
  double get totalWalkHours => dailyStats.fold(0, (sum, item) => sum + item.walkHours);
  int get totalFalls => dailyStats.fold(0, (sum, item) => sum + item.falls);
}
