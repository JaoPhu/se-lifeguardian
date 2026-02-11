import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'history_repository.dart';
import 'history_repository_impl.dart';
import '../domain/daily_stats_model.dart';
import '../domain/weekly_stats_model.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl();
});

final dailyStatsProvider = FutureProvider.family<DailyStatsModel, DateTime>((ref, date) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getDailyStats(date);
});

final weeklyStatsProvider = FutureProvider.family<WeeklyStatsModel, DateTime>((ref, startDate) async {
   final repository = ref.watch(historyRepositoryProvider);
   return repository.getWeeklyStats(startDate);
});
