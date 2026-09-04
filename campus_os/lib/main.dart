import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/data_service.dart';
import 'services/campus_ai_service.dart';
import 'providers/schedule_provider.dart';
import 'providers/room_provider.dart';
import 'providers/event_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const appCheckDebugToken = String.fromEnvironment(
    'FIREBASE_APPCHECK_DEBUG_TOKEN',
    defaultValue: 'd10d115f-8204-4e32-a00a-faa278506575',
  );

  if (kDebugMode && appCheckDebugToken.isEmpty) {
    debugPrint(
      'Firebase App Check debug token not set. Run with '
      '--dart-define=FIREBASE_APPCHECK_DEBUG_TOKEN=<token> after '
      'registering the token in Firebase App Check.',
    );
  }

  await FirebaseAppCheck.instance.activate(
    providerWeb: WebDebugProvider(
      debugToken: appCheckDebugToken.isEmpty ? null : appCheckDebugToken,
    ),
    providerAndroid: AndroidDebugProvider(
      debugToken: appCheckDebugToken.isEmpty ? null : appCheckDebugToken,
    ),
    providerApple: AppleDebugProvider(
      debugToken: appCheckDebugToken.isEmpty ? null : appCheckDebugToken,
    ),
  );

  // Seed Firestore from bundled JSON assets when the collections are empty.
  final dataService = DataService();
  await dataService.loadSeedData();

  final aiService = CampusAiService(dataService);

  runApp(CampusOSApp(dataService: dataService, aiService: aiService));
}

class CampusOSApp extends StatelessWidget {
  final DataService dataService;
  final CampusAiService aiService;

  const CampusOSApp({super.key, required this.dataService, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider(dataService)),
        ChangeNotifierProvider(create: (_) => RoomProvider(dataService)),
        ChangeNotifierProvider(create: (_) => EventProvider(dataService)),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(dataService)),
        ChangeNotifierProvider(create: (_) => AssignmentProvider(dataService)),
        ChangeNotifierProvider(create: (_) => ChatProvider(aiService)),
      ],
      child: MaterialApp(
        title: 'CampusOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.isResolvingAuth) {
          return const _AuthLoadingScreen();
        }
        return session.currentUser == null ? const LoginScreen() : const MainShell();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your CampusOS profile...'),
          ],
        ),
      ),
    );
  }
}
