import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'screen_constants.dart';
import 'simple_screen.dart';
import 'status_screen.dart';
import 'system_ui.dart';
import 'theme_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _gateVersion = 0;

  void _refreshGate() => setState(() => _gateVersion++);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: _BootstrapGate(
            key: ValueKey(_gateVersion),
            onOnboardingComplete: _refreshGate,
          ),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? darkBackground : lightBackground;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ).copyWith(primary: primaryColor, surface: background),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: systemOverlayStyle(background),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cardBackground : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 1.4),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.white70 : Colors.black54,
        backgroundColor: background,
      ),
    );
  }
}

class _BootstrapGate extends StatelessWidget {
  const _BootstrapGate({super.key, required this.onOnboardingComplete});

  final VoidCallback onOnboardingComplete;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const StatusScreen(
            title: 'Loading DuelXZone',
            subtitle: 'Preparing your arena...',
            loading: true,
          );
        }
        if (snapshot.hasError) {
          return const StatusScreen(
            title: 'Firebase setup required',
            subtitle: 'Connect Firebase config to continue.',
          );
        }
        return _AuthGate(onOnboardingComplete: onOnboardingComplete);
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.onOnboardingComplete});

  final VoidCallback onOnboardingComplete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StatusScreen(
            title: 'Loading DuelXZone',
            subtitle: 'Preparing your arena...',
            loading: true,
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return OnboardingScreen(onCompleted: onOnboardingComplete);
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState != ConnectionState.done) {
              return const StatusScreen(
                title: 'Loading DuelXZone',
                subtitle: 'Preparing your arena...',
                loading: true,
              );
            }

            final data = docSnapshot.data?.data();
            if (isProfileComplete(data)) {
              return const AppShell();
            }

            return OnboardingScreen(
              existingUser: user,
              existingData: data,
              onCompleted: onOnboardingComplete,
            );
          },
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const SimpleScreen(title: 'Battles'),
      const SimpleScreen(title: 'Leaderboard'),
      const ProfileScreen(),
    ];
    final background = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(background),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_mma_outlined),
              activeIcon: Icon(Icons.sports_mma),
              label: 'Battles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
