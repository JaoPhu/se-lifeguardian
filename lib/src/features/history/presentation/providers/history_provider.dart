import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/history_repository_provider.dart'; // Import existing provider
import '../../domain/history_model.dart';

// historyRepositoryProvider is now imported from data layer to avoid duplication

final historyListProvider =
    FutureProvider<List<DailyHistory>>((ref) async {
  final repo = ref.read(historyRepositoryProvider);
  return repo.fetchHistory();
});
