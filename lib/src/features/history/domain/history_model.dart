class DailyHistory {
  final DateTime date;
  final double relaxHours;
  final double workHours;
  final double walkHours;
  final int fallCount;

  DailyHistory({
    required this.date,
    required this.relaxHours,
    required this.workHours,
    required this.walkHours,
    required this.fallCount,
  });

  bool get hasRisk => fallCount > 0;

  double get totalHours => relaxHours + workHours + walkHours;
}
