import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'services/streak_service.dart';
import 'services/task_service.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final appState = AppState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appState),
        Provider<StreakService>(create: (_) => StreakService()),
        Provider<TaskService>(create: (_) => TaskService()),
      ],
      child: MaterialApp(
        title: 'Power6',
        theme: ThemeData(primarySwatch: Colors.teal),
        routes: {
          '/signup': (ctx) => const SignUpScreen(),
          // add other routes here (e.g., '/home': (ctx) => const HomeScreen(), etc.)
        },
        home: const PowerApp(),
      ),
    ),
  );
}