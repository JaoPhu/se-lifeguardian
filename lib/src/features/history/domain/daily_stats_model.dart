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

  factory DailyStatsModel.fromDoc(Object? doc) {
    if (doc is Map<String, dynamic>) {
      final date = doc['date'] as String? ?? '';
      return DailyStatsModel(
        date: DateTime.tryParse(date) ?? DateTime.now(),
        relaxHours: (doc['relaxHours'] ?? 0.0).toDouble(),
        workHours: (doc['workHours'] ?? 0.0).toDouble(),
        walkHours: (doc['walkHours'] ?? 0.0).toDouble(),
        falls: (doc['falls'] ?? 0).toInt(),
      );
    }
    try {
      final data = (doc as dynamic).data() as Map<String, dynamic>;
      final date = data['date'] as String? ?? '';
      return DailyStatsModel(
        date: DateTime.tryParse(date) ?? DateTime.now(),
        relaxHours: (data['relaxHours'] ?? 0.0).toDouble(),
        workHours: (data['workHours'] ?? 0.0).toDouble(),
        walkHours: (data['walkHours'] ?? 0.0).toDouble(),
        falls: (data['falls'] ?? 0).toInt(),
      );
    } catch (e) {
      return DailyStatsModel(
        date: DateTime.now(),
        relaxHours: 0,
        workHours: 0,
        walkHours: 0,
        falls: 0,
      );
    }
  }
}
