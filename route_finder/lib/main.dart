import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
  } on Exception catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4C6FFF),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        ),
    );
  }
}
