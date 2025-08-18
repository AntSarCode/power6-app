import 'package:flutter/material.dart';

// Brand palette
const kBrandTeal = Color(0xFF008080);
const kBg = Color(0xFF121212);
const kSurface = Color(0xFF142021);
const kInputBg = Color(0xFF102A2A);

final ThemeData appTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.dark,
  primarySwatch: Colors.teal,
  primaryColor: kBrandTeal,
  scaffoldBackgroundColor: kBg,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: kBrandTeal,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black54,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w700,
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
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: kInputBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: kBrandTeal, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.white70),
    hintStyle: TextStyle(color: Colors.white54),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.white,
    selectionHandleColor: Colors.white,
    selectionColor: Color(0x3348D1CC),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBrandTeal,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
      elevation: 6,
      shadowColor: Colors.black45,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kSurface,
    selectedItemColor: kBrandTeal,
    unselectedItemColor: Colors.white60,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: kBrandTeal,
    contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    behavior: SnackBarBehavior.floating,
  ),
);
