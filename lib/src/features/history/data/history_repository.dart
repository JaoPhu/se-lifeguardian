import '../domain/history_model.dart';
import '../domain/daily_stats_model.dart';
import '../domain/weekly_stats_model.dart';
import '../../statistics/domain/simulation_event.dart';

abstract class HistoryRepository {
  Future<List<DailyHistory>> fetchHistory({String? uid});
  Future<DailyStatsModel> getDailyStats(DateTime date, {String? uid});
  Future<WeeklyStatsModel> getWeeklyStats(DateTime startDate, {String? uid});
  Future<List<SimulationEvent>> fetchEventsForDay(DateTime date, {String? uid});
}
