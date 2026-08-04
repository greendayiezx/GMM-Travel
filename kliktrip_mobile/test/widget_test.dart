import 'package:flutter_test/flutter_test.dart';
import 'package:kliktrip_mobile/main.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KlikTripApp());
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
