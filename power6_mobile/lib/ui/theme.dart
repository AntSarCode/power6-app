import 'package:flutter/material.dart';

const Color kBrandSeed = Color(0xFFFF6A00);
const Color kScaffoldDark = Color(0xFF0B1416);

ThemeData buildDarkTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: kBrandSeed,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: kScaffoldDark,
    canvasColor: Colors.transparent,
    cardColor: cs.surface.withOpacity(0.10),
    dialogBackgroundColor: cs.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    iconTheme: IconThemeData(color: cs.onSurfaceVariant),
    dividerColor: cs.outlineVariant.withOpacity(0.40),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface.withOpacity(0.08),
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.70)),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.secondary),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return cs.secondary.withOpacity(0.40);
          }
          return cs.secondary;
        }),
        foregroundColor: WidgetStateProperty.all(cs.onSecondary),
        elevation: WidgetStateProperty.all(0),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cs.surface.withOpacity(0.18),
      selectedColor: cs.secondary.withOpacity(0.25),
      disabledColor: cs.surface.withOpacity(0.10),
      side: BorderSide(color: cs.outlineVariant.withOpacity(0.40)),
      labelStyle: TextStyle(color: cs.onSurface),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      horizontalTitleGap: 12,
      dense: true,
    ),
  );
}
ThemeData buildLightTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: kBrandSeed,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: Colors.white,
  );
}
