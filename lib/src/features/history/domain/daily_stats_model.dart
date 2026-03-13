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

  static DailyStatsModel calculate(DateTime date, List<dynamic> events) {
    double relax = 0;
    double work = 0;
    double walk = 0;
    int falls = 0;

    for (var event in events) {
      final type = (event.type as String).toLowerCase();
      final durationSeconds = (event.durationSeconds as int? ?? 0);
      final durationHrs = (durationSeconds < 0 ? 0 : durationSeconds) / 3600.0;
      
      if (type == 'sitting' || type == 'laying' || type == 'relax') {
        relax += durationHrs;
      } else if (type == 'working' || type == 'work' || type == 'standing') {
        work += durationHrs;
      } else if (type == 'walking' || type == 'walk' || type == 'exercise') {
        walk += durationHrs;
      }

      if (event.isCritical == true || type.contains('fall')) {
        falls++;
      }
    }

    return DailyStatsModel(
      date: date,
      relaxHours: relax,
      workHours: work,
      walkHours: walk,
      falls: falls,
    );
  }
}
