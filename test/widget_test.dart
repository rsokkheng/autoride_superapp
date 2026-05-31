import 'package:flutter_test/flutter_test.dart';
import 'package:autoride_superapp/main.dart';

void main() {
  testWidgets('App smoke test — role selection screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoRideApp());
    await tester.pumpAndSettle();
    expect(find.text('AutoRide'), findsWidgets);
  });
}
