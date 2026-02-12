import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/history_model.dart';
import '../domain/daily_stats_model.dart';
import '../domain/weekly_stats_model.dart';
import 'history_repository.dart';
import '../../statistics/domain/simulation_event.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HistoryRepositoryImpl(this._firestore, this._auth);

  @override
  Future<List<DailyHistory>> fetchHistory() async {
     // TODO: Implement full history list flow if needed
     // For now return empty or keep mock if strictly required for other screens
     // But user asked for Weekly Chart real data.
     return []; 
  }

  @override
  Future<DailyStatsModel> getDailyStats(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return _emptyDailyStats(date);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('events')
          .where('startTimeMs', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('startTimeMs', isLessThan: endOfDay.millisecondsSinceEpoch)
          .get();

      final events = snapshot.docs.map((doc) => SimulationEvent.fromJson(doc.data())).toList();
      return _calculateStats(date, events);
    } catch (e) {
      print('Error fetching daily stats: $e');
      return _emptyDailyStats(date);
    }
  }

  @override
  Future<WeeklyStatsModel> getWeeklyStats(DateTime startDate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return WeeklyStatsModel(dailyStats: []);

    // Ensure we cover the full range from requested start date (Monday?) to end of week
    // User chart usually shows Mon-Sun or past 7 days.
    // Let's assume startDate is the first day (e.g. Mon).
    final startRange = DateTime(startDate.year, startDate.month, startDate.day);
    final endRange = startRange.add(const Duration(days: 7));

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('events')
          .where('startTimeMs', isGreaterThanOrEqualTo: startRange.millisecondsSinceEpoch)
          .where('startTimeMs', isLessThan: endRange.millisecondsSinceEpoch)
          .get();

      final allEvents = snapshot.docs.map((doc) => SimulationEvent.fromJson(doc.data())).toList();

      final List<DailyStatsModel> weeklyStats = [];
      for (int i = 0; i < 7; i++) {
        final currentDay = startRange.add(Duration(days: i));
        // Filter events for this specific day
        final dayEvents = allEvents.where((e) {
          if (e.startTimeMs == null) return false;
          final eDate = DateTime.fromMillisecondsSinceEpoch(e.startTimeMs!);
          return eDate.year == currentDay.year && 
                 eDate.month == currentDay.month && 
                 eDate.day == currentDay.day;
        }).toList();

        weeklyStats.add(_calculateStats(currentDay, dayEvents));
      }

      return WeeklyStatsModel(dailyStats: weeklyStats);

    } catch (e) {
      print('Error fetching weekly stats: $e');
      return WeeklyStatsModel(dailyStats: []);
    }
  }

  DailyStatsModel _calculateStats(DateTime date, List<SimulationEvent> events) {
    double relax = 0;
    double work = 0;
    double walk = 0;
    int falls = 0;

    for (var event in events) {
      final type = event.type.toLowerCase();
      // Use seconds if available
      final durationHrs = (event.durationSeconds ?? 0) / 3600.0;
      
      if (type == 'sitting' || type == 'laying' || type == 'relax') {
        relax += durationHrs;
      } else if (type == 'working' || type == 'work' || type == 'standing') {
        work += durationHrs;
      } else if (type == 'walking' || type == 'walk' || type == 'exercise') {
        walk += durationHrs;
      }

      if (event.isCritical || type == 'falling' || type == 'fall') {
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

  DailyStatsModel _emptyDailyStats(DateTime date) {
    return DailyStatsModel(
      date: date,
      relaxHours: 0,
      workHours: 0,
      walkHours: 0,
      falls: 0,
    );
  }
}
