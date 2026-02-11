import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/app_router.dart';
import 'common/app_theme.dart';
import 'common_widgets/theme_provider.dart';

class LifeguardianApp extends ConsumerWidget {
  const LifeguardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'LifeGuardian',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
