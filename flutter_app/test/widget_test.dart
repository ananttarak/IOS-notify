import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storepulse/main.dart';

void main() {
  testWidgets('StorePulse app boots and displays dashboard navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StorePulseApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main app bar title and bottom navigation tabs exist
    expect(find.text('StorePulse'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('Scheduler'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Verify status indicator appears
    expect(find.text('SCHEDULER STATUS'), findsOneWidget);
  });
}
