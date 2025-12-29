import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder_app/Provider/reminder_provider.dart';
import 'package:reminder_app/Services/notification_service.dart';
import 'HomePage/MasterHomePage.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize notification service
//   await NotificationService.instance.initialize();

//   runApp(const MyApp());
// }
void main() async {
  // ← Add async
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize(); // ← Add this line
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ReminderProvider())],
      child: MaterialApp(
        title: 'Reminder App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: const MasterHomePage(),
      ),
    );
  }
}
