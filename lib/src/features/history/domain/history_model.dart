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

  factory DailyHistory.fromDoc(Object? doc) {
    // If using Cloud Firestore DocumentSnapshot
    if (doc is Map<String, dynamic>) {
      final date = doc['date'] as String? ?? '';
      return DailyHistory(
        date: DateTime.tryParse(date) ?? DateTime.now(),
        relaxHours: (doc['relaxHours'] ?? 0.0).toDouble(),
        workHours: (doc['workHours'] ?? 0.0).toDouble(),
        walkHours: (doc['walkHours'] ?? 0.0).toDouble(),
        fallCount: (doc['fallCount'] ?? 0).toInt(),
      );
    }
    // Handle the case where doc is actually a QueryDocumentSnapshot or DocumentSnapshot
    // This is a bit hacky but works for the current implementation pattern
    try {
      final data = (doc as dynamic).data() as Map<String, dynamic>;
      final date = data['date'] as String? ?? '';
      return DailyHistory(
        date: DateTime.tryParse(date) ?? DateTime.now(),
        relaxHours: (data['relaxHours'] ?? 0.0).toDouble(),
        workHours: (data['workHours'] ?? 0.0).toDouble(),
        walkHours: (data['walkHours'] ?? 0.0).toDouble(),
        fallCount: (data['fallCount'] ?? 0).toInt(),
      );
    } catch (e) {
      return DailyHistory(
        date: DateTime.now(),
        relaxHours: 0,
        workHours: 0,
        walkHours: 0,
        fallCount: 0,
      );
    }
  }
}
