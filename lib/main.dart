import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/main_navigation.dart';
import 'screens/add_habit_screen.dart';
import 'screens/ai_habits_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Life Companion',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const AppRouter(),
        routes: {
          '/add-habit': (context) => const AddHabitScreen(),
          '/ai-habits': (context) => const AIHabitsScreen(),
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Show loading screen while initializing
        if (!appState.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Color(0xFF6366F1),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          );
        }

        if (!appState.isLoggedIn) {
          return const LoginScreen();
        }
        if (appState.isOnboarded) {
          return const MainNavigation();
        } else {
          return const OnboardingFlow();
        }
      },
    );
  }
}
