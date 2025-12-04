import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:route_finder/firebase_options.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/pages/dashboard/dashboard_page.dart';
import 'package:route_finder/pages/landing/landing_page.dart';

void main() async {
  await _setup();
  runApp(const MyApp());
}

Future<void> _setup() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await dotenv.load(fileName: ".env");
    debugPrint(".env file loaded");
  } on Exception catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Route Finder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF4C6FFF),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Nunito',
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF4C6FFF)),
        ),
        home: StreamBuilder(
          stream: FirebaseHelper.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final user = snapshot.data;
              if (user == null) {
                return const LandingPage();
              } else {
                return const DashboardPage();
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
