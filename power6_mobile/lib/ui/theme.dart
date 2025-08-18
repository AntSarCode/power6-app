import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.deepPurple,
  scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E2C), // Deep slate/navy blend
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black54,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white70),
    bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1F1B2E), // Dark purple background for inputs
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF8E7CC3), width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white38),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF8E7CC3), // Vibrant lavender accent
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 6,
      shadowColor: Colors.black45,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E2C),
    selectedItemColor: Color(0xFF8E7CC3),
    unselectedItemColor: Colors.white54,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(color: Colors.white54),
  ),
  cardTheme: CardThemeData(
  color: const Color(0xFF1F1B2E),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
  elevation: 6,
  margin: const EdgeInsets.all(12),
),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF8E7CC3),
    contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    behavior: SnackBarBehavior.floating,
  ),
);
