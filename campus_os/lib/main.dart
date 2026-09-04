import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/data_service.dart';
import 'providers/schedule_provider.dart';
import 'providers/room_provider.dart';
import 'providers/event_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load seed data from bundled JSON assets
  final dataService = DataService();
  await dataService.loadSeedData();

  runApp(CampusOSApp(dataService: dataService));
}

class CampusOSApp extends StatelessWidget {
  final DataService dataService;

  const CampusOSApp({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider(dataService)),
        ChangeNotifierProvider(create: (_) => RoomProvider(dataService)),
        ChangeNotifierProvider(create: (_) => EventProvider(dataService)),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(dataService)),
        ChangeNotifierProvider(create: (_) => AssignmentProvider(dataService)),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'CampusOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainShell(),
      ),
    );
  }
}
