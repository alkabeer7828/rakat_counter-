import 'package:flutter_test/flutter_test.dart';
import 'package:sajdah_counter/main.dart';

void main() {
  testWidgets('Counter screen shows rakat and sajdah labels', (tester) async {
    await tester.pumpWidget(const SajdahCounterApp());

    expect(find.text('RAKAT'), findsOneWidget);
    expect(find.text('SAJDAH'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });
}
