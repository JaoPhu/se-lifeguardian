import 'package:flutter_test/flutter_test.dart';
import 'package:lifeguardian/src/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeguardian/src/common/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    // We override sharedPreferencesProvider with the instance we just got.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LifeguardianApp(),
      ),
    );

    // Verify that the app builds without crashing
    expect(find.byType(LifeguardianApp), findsOneWidget);
  });
}
