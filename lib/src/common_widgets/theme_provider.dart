import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/shared_preferences_provider.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.light;
  }

  void toggle() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_themeKey, newMode.index);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
