class DailyStatsModel {
  final DateTime date;
  final double relaxHours;
  final double workHours;
  final double walkHours;
  final int falls;

  DailyStatsModel({
    required this.date,
    required this.relaxHours,
    required this.workHours,
    required this.walkHours,
    required this.falls,
  });
}
