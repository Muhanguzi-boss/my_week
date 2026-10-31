import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart'; // created by: flutterfire configure
import 'screens/login_screen.dart';
import 'screens/week_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyWeekApp());
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF00897B),
);

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Week',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen when nobody is signed in, the week otherwise.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return WeekScreen(user: user);
      },
    );
  }
}
