import 'dart:math';

import '../domain/history_model.dart';
import '../domain/daily_stats_model.dart';
import '../domain/weekly_stats_model.dart';
import 'history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  @override
  Future<List<DailyHistory>> fetchHistory() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    final random = Random();

    return List.generate(14, (index) {
      final date = now.subtract(Duration(days: index));
      // Generate some consistent-ish data based on date hash or just random
      return _generateDailyHistory(date, random);
    });
  }

  @override
  Future<DailyStatsModel> getDailyStats(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final random = Random(date.hashCode); // Consistent random based on date
    
    return DailyStatsModel(
      date: date,
      relaxHours: _randomDouble(random, 5),
      workHours: _randomDouble(random, 8),
      walkHours: _randomDouble(random, 3),
      falls: random.nextDouble() < 0.1 ? 1 : 0,
    );
  }

  @override
  Future<WeeklyStatsModel> getWeeklyStats(DateTime startDate) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final random = Random(startDate.hashCode);

    final dailyStats = List.generate(7, (index) {
       final date = startDate.add(Duration(days: index));
       return DailyStatsModel(
         date: date,
         relaxHours: _randomDouble(random, 5),
         workHours: _randomDouble(random, 8),
         walkHours: _randomDouble(random, 3),
         falls: random.nextDouble() < 0.1 ? 1 : 0,
       );
    });

    return WeeklyStatsModel(dailyStats: dailyStats);
  }

  DailyHistory _generateDailyHistory(DateTime date, Random random) {
    final relax = (random.nextDouble() * 5).clamp(0.0, 5.0);
    final work = (random.nextDouble() * 8).clamp(0.0, 8.0);
    final walk = (random.nextDouble() * 3).clamp(0.0, 3.0);
    final falls = random.nextDouble() < 0.2 ? random.nextInt(3) + 1 : 0;

    return DailyHistory(
      date: date,
      relaxHours: double.parse(relax.toStringAsFixed(1)),
      workHours: double.parse(work.toStringAsFixed(1)),
      walkHours: double.parse(walk.toStringAsFixed(1)),
      fallCount: falls,
    );
  }

  double _randomDouble(Random random, double max) {
    return double.parse((random.nextDouble() * max).toStringAsFixed(1));
  }
}
