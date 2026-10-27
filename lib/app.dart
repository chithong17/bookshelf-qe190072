import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';

class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BookShelf',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final user = snapshot.data;
        return user == null ? const HomeScreen() : LibraryScreen(user: user);
      },
    ),
  );
}
