import '../domain/history_model.dart';
import '../domain/daily_stats_model.dart';
import '../domain/weekly_stats_model.dart';

abstract class HistoryRepository {
  Future<List<DailyHistory>> fetchHistory();
  Future<DailyStatsModel> getDailyStats(DateTime date);
  Future<WeeklyStatsModel> getWeeklyStats(DateTime startDate);
}
