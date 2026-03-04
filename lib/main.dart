import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/loading_page.dart';
import 'screens/saved_campaigns.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  final savedNotifier = SavedCampaignsNotifier();
  SavedNotifierProvider.setFallback(savedNotifier);
  runApp(MyApp(savedNotifier: savedNotifier));
}

class MyApp extends StatelessWidget {
  final SavedCampaignsNotifier savedNotifier;

  const MyApp({super.key, required this.savedNotifier});

  @override
  Widget build(BuildContext context) {
    return SavedNotifierProvider(
      notifier: savedNotifier,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DanaKita',
        theme: buildAppTheme(),
        home: const LoadingPage(),
      ),
    );
  }
}
