import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrialState {
  final bool isExpired;
  final int daysRemaining;
  final bool isLoading;

  TrialState({
    this.isExpired = false,
    this.daysRemaining = 7,
    this.isLoading = true,
  });
}

class TrialNotifier extends StateNotifier<TrialState> {
  TrialNotifier() : super(TrialState()) {
    _checkTrialStatus();
  }

  static const _installDateKey = 'app_install_date_v1';
  static const _trialDurationDays = 7;

  Future<void> _checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    int? installTimestamp = prefs.getInt(_installDateKey);
    
    if (installTimestamp == null) {
      // First run, save install date
      installTimestamp = now.millisecondsSinceEpoch;
      await prefs.setInt(_installDateKey, installTimestamp);
    }

    final installDate = DateTime.fromMillisecondsSinceEpoch(installTimestamp);
    final expirationDate = installDate.add(const Duration(days: _trialDurationDays));
    
    final daysRemaining = expirationDate.difference(now).inDays;
    final isExpired = now.isAfter(expirationDate);

    state = TrialState(
      isExpired: isExpired,
      daysRemaining: daysRemaining < 0 ? 0 : daysRemaining,
      isLoading: false,
    );
  }

  Future<void> resetTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_installDateKey);
    await _checkTrialStatus();
  }
}

final trialProvider = StateNotifierProvider<TrialNotifier, TrialState>((ref) {
  return TrialNotifier();
});
