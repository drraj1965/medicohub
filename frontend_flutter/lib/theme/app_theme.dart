import 'package:flutter/material.dart';

enum MedicoHubThemePreset {
  dark,
  light,
  rose,
  mint,
}

extension MedicoHubThemePresetLabel on MedicoHubThemePreset {
  String get label {
    switch (this) {
      case MedicoHubThemePreset.dark:
        return 'Dark';
      case MedicoHubThemePreset.light:
        return 'Light';
      case MedicoHubThemePreset.rose:
        return 'Pink';
      case MedicoHubThemePreset.mint:
        return 'Light Green';
    }
  }
}

ThemeData buildMedicoHubTheme(MedicoHubThemePreset preset) {
  switch (preset) {
    case MedicoHubThemePreset.dark:
      return _buildTheme(
        seed: const Color(0xFF4F8C73),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1014),
        surface: const Color(0xFF11161A),
        cardColor: const Color(0xFF161E24),
        fieldColor: const Color(0xFF1A232A),
      );
    case MedicoHubThemePreset.light:
      return _buildTheme(
        seed: const Color(0xFF3E6B72),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        surface: const Color(0xFFFFFFFF),
        cardColor: const Color(0xFFFFFFFF),
        fieldColor: const Color(0xFFE8EEF0),
      );
    case MedicoHubThemePreset.rose:
      return _buildTheme(
        seed: const Color(0xFFC95B86),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF2F7),
        surface: const Color(0xFFFFFBFD),
        cardColor: const Color(0xFFFFF9FC),
        fieldColor: const Color(0xFFFFE4EF),
      );
    case MedicoHubThemePreset.mint:
      return _buildTheme(
        seed: const Color(0xFF4E9C72),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1FAF3),
        surface: const Color(0xFFFCFFFC),
        cardColor: const Color(0xFFF8FFF8),
        fieldColor: const Color(0xFFE0F2E4),
      );
  }
}

ThemeData _buildTheme({
  required Color seed,
  required Brightness brightness,
  required Color scaffoldBackgroundColor,
  required Color surface,
  required Color cardColor,
  required Color fieldColor,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    surface: surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    cardTheme: CardThemeData(
      color: cardColor,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
