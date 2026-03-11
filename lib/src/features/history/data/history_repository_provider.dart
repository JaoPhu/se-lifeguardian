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

final dailyStatsProvider = FutureProvider.family<DailyStatsModel, DateTime>((ref, date) async {
  final repository = ref.watch(historyRepositoryProvider);
  final targetUid = ref.watch(resolvedTargetUidProvider);
  return repository.getDailyStats(date, uid: targetUid);
});

final weeklyStatsProvider = FutureProvider.family<WeeklyStatsModel, DateTime>((ref, startDate) async {
   final repository = ref.watch(historyRepositoryProvider);
   final targetUid = ref.watch(resolvedTargetUidProvider);
   return repository.getWeeklyStats(startDate, uid: targetUid);
});

final dailyEventsProvider = FutureProvider.family<List<SimulationEvent>, DateTime>((ref, date) async {
  final repository = ref.watch(historyRepositoryProvider);
  final targetUid = ref.watch(resolvedTargetUidProvider);
  return repository.fetchEventsForDay(date, uid: targetUid);
});
