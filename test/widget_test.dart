import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autoride_superapp/main.dart';
import 'package:autoride_superapp/providers/theme_provider.dart';
import 'package:autoride_superapp/providers/biometric_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test — role selection screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => BiometricProvider()),
        ],
        child: const AutoRideApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1850));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  });
}
