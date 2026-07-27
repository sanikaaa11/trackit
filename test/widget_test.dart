import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trackit/main.dart';

void main() {
  testWidgets('TrackIt app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TrackItApp(),
      ),
    );

    expect(find.byType(TrackItApp), findsOneWidget);
  });
}
