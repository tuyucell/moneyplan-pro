import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:invest_guide/main.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Trigger a single frame
    await tester.pump();

    // Verify that the app builds without throwing errors
    expect(find.byType(MyApp), findsOneWidget);
  });
}
