import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_repository.dart';
import 'history_repository_impl.dart';
import '../domain/daily_stats_model.dart';
import '../domain/weekly_stats_model.dart';
import '../../statistics/domain/simulation_event.dart';

import '../../group/providers/group_providers.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return HistoryRepositoryImpl(firestore, auth);
});

final dailyStatsProvider = StreamProvider.family<DailyStatsModel, DateTime>((ref, date) {
  final repository = ref.watch(historyRepositoryProvider);
  final targetUid = ref.watch(resolvedTargetUidProvider);
  return repository.watchDailyEvents(date, uid: targetUid).map((events) {
    return DailyStatsModel.calculate(date, events);
  });
});

final weeklyStatsProvider = StreamProvider.family<WeeklyStatsModel, DateTime>((ref, startDate) {
  final repository = ref.watch(historyRepositoryProvider);
  final targetUid = ref.watch(resolvedTargetUidProvider);
  
  return repository.watchWeeklyEvents(startDate, uid: targetUid).map((allEvents) {
     final List<DailyStatsModel> weeklyStats = [];
     for (int i = 0; i < 7; i++) {
       final currentDay = startDate.add(Duration(days: i));
       final dayEvents = allEvents.where((e) {
         if (e.startTimeMs == null) return false;
         final eDate = DateTime.fromMillisecondsSinceEpoch(e.startTimeMs!);
         return eDate.year == currentDay.year && 
                eDate.month == currentDay.month && 
                eDate.day == currentDay.day;
       }).toList();

       weeklyStats.add(DailyStatsModel.calculate(currentDay, dayEvents));
     }
     return WeeklyStatsModel(dailyStats: weeklyStats);
  });
});

final dailyEventsProvider = StreamProvider.family<List<SimulationEvent>, DateTime>((ref, date) {
  final repository = ref.watch(historyRepositoryProvider);
  final targetUid = ref.watch(resolvedTargetUidProvider);
  return repository.watchDailyEvents(date, uid: targetUid);
});
