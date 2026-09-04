import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _ensureAuthenticated();

  // Seed Firestore from bundled JSON assets when the collections are empty.
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

Future<void> _ensureAuthenticated() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) return;

  await auth.signInAnonymously();
}
