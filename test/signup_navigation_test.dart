import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_flutter_app/providers/app_state.dart';
import 'package:my_flutter_app/screens/auth/signup_screen.dart';
import 'package:my_flutter_app/screens/auth/login_screen.dart';
import 'package:my_flutter_app/screens/main_navigation.dart';
import 'package:my_flutter_app/screens/onboarding/onboarding_flow.dart';
import 'package:my_flutter_app/screens/onboarding/energy_step.dart';
import 'package:my_flutter_app/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup navigates to onboarding after success', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearAllTestValues();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => TestAppState(),
        child: const MaterialApp(home: SignupScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextFormField).at(1), 'jane@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
  });

  testWidgets('complete setup navigates to main navigation', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => CompletionAppState(),
        child: const MaterialApp(home: Scaffold(body: EnergyStep())),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Complete Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(MainNavigation), findsOneWidget);
  });

  testWidgets('logout navigates back to login screen', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearAllTestValues();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => LogoutAppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Log Out'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log Out'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Log Out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

class TestAppState extends AppState {
  @override
  Future<bool> signup(String name, String email, String password) async {
    setAuthState(
      isLoggedIn: true,
      isOnboarded: false,
      userId: 'user-123',
      userName: name,
      userEmail: email,
    );
    return true;
  }
}

class CompletionAppState extends AppState {
  @override
  Future<void> updateUserProfile(profile) async {}

  @override
  Future<bool> completeOnboarding() async {
    setAuthState(
      isLoggedIn: true,
      isOnboarded: true,
      userId: 'user-123',
      userName: 'Jane Doe',
      userEmail: 'jane@example.com',
    );
    return true;
  }
}

class LogoutAppState extends AppState {
  LogoutAppState() {
    setAuthState(
      isLoggedIn: true,
      isOnboarded: true,
      userId: 'user-123',
      userName: 'Jane Doe',
      userEmail: 'jane@example.com',
    );
  }

  @override
  Future<void> logout() async {
    setAuthState(
      isLoggedIn: false,
      isOnboarded: false,
      userId: null,
      userName: '',
      userEmail: '',
    );
  }
}
