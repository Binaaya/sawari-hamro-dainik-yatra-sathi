import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_app.dart';
import 'screens/operator/operator_app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // Initialize push notifications
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Allow graceful fallback if Firebase is unavailable
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SawariApp(),
    ),
  );
}

class SawariApp extends StatefulWidget {
  const SawariApp({super.key});

  @override
  State<SawariApp> createState() => _SawariAppState();
}

class _SawariAppState extends State<SawariApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.initialize();
    setState(() => _initialized = true);
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _themeMode =
            brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
      } else if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Show loading while initializing
        if (!_initialized || appState.isLoading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Sawari',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          home: appState.isAuthenticated
              ? (appState.currentUser?.isOperator == true
                  ? OperatorApp(onLogout: () => appState.logout())
                  : MainApp(
                      onLogout: () => appState.logout(),
                      themeMode: _themeMode,
                      onToggleTheme: _toggleTheme,
                    ))
              : const LoginScreen(),
        );
      },
    );
  }
}
