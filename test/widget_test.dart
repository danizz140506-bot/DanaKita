import 'package:flutter_test/flutter_test.dart';

import 'package:fundraising_app/main.dart';
import 'package:fundraising_app/screens/saved_campaigns.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    final notifier = SavedCampaignsNotifier();
    await tester.pumpWidget(MyApp(savedNotifier: notifier));
    expect(find.text('DanaKita'), findsOneWidget);
  });
}
