import 'package:flutter/material.dart';

const String kDefaultCustomThemeHex = '#6F46FF';
const List<String> kThemeHexPalette = <String>[
  '#6F46FF',
  '#22C55E',
  '#FF9E0B',
  '#EC4899',
  '#06B6D4',
  '#8B5CF6',
  '#0F172A',
  '#64748B',
  '#4F46E5',
  '#16A34A',
  '#F97316',
  '#0EA5E9',
];

enum MedicoHubThemePreset {
  dark,
  light,
  rose,
  mint,
  ocean,
  amber,
  lavender,
  slate,
  custom,
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
      case MedicoHubThemePreset.ocean:
        return 'Ocean Blue';
      case MedicoHubThemePreset.amber:
        return 'Warm Amber';
      case MedicoHubThemePreset.lavender:
        return 'Lavender';
      case MedicoHubThemePreset.slate:
        return 'Slate';
      case MedicoHubThemePreset.custom:
        return 'Custom HEX';
    }
  }
}

class MedicoHubThemeConfig {
  const MedicoHubThemeConfig({
    required this.preset,
    this.customSeedHex = kDefaultCustomThemeHex,
    this.customDarkMode = false,
  });

  final MedicoHubThemePreset preset;
  final String customSeedHex;
  final bool customDarkMode;

  MedicoHubThemeConfig copyWith({
    MedicoHubThemePreset? preset,
    String? customSeedHex,
    bool? customDarkMode,
  }) {
    return MedicoHubThemeConfig(
      preset: preset ?? this.preset,
      customSeedHex: customSeedHex ?? this.customSeedHex,
      customDarkMode: customDarkMode ?? this.customDarkMode,
    );
  }
}

ThemeData buildMedicoHubTheme(MedicoHubThemeConfig config) {
  switch (config.preset) {
    case MedicoHubThemePreset.dark:
      return _buildTheme(
        seed: const Color(0xFF6F46FF),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF091122),
        surface: const Color(0xFF101A2B),
        cardColor: const Color(0xFF122038),
        fieldColor: const Color(0xFF18253E),
      );
    case MedicoHubThemePreset.light:
      return _buildTheme(
        seed: const Color(0xFF0F172A),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        surface: const Color(0xFFFFFFFF),
        cardColor: const Color(0xFFFFFFFF),
        fieldColor: const Color(0xFFF1F5FB),
      );
    case MedicoHubThemePreset.rose:
      return _buildTheme(
        seed: const Color(0xFFEC4899),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF2F7),
        surface: const Color(0xFFFFFBFD),
        cardColor: const Color(0xFFFFF9FC),
        fieldColor: const Color(0xFFFFE4EF),
      );
    case MedicoHubThemePreset.mint:
      return _buildTheme(
        seed: const Color(0xFF22C55E),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1FAF3),
        surface: const Color(0xFFFCFFFC),
        cardColor: const Color(0xFFF8FFF8),
        fieldColor: const Color(0xFFE0F2E4),
      );
    case MedicoHubThemePreset.ocean:
      return _buildTheme(
        seed: const Color(0xFF06B6D4),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F8FF),
        surface: const Color(0xFFFDFEFF),
        cardColor: const Color(0xFFF7FBFF),
        fieldColor: const Color(0xFFDDEFFC),
      );
    case MedicoHubThemePreset.amber:
      return _buildTheme(
        seed: const Color(0xFFFF9E0B),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF8ED),
        surface: const Color(0xFFFFFDF9),
        cardColor: const Color(0xFFFFFBF2),
        fieldColor: const Color(0xFFF7E7C8),
      );
    case MedicoHubThemePreset.lavender:
      return _buildTheme(
        seed: const Color(0xFF8B5CF6),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F2FF),
        surface: const Color(0xFFFEFDFF),
        cardColor: const Color(0xFFF8F6FF),
        fieldColor: const Color(0xFFE8E0FF),
      );
    case MedicoHubThemePreset.slate:
      return _buildTheme(
        seed: const Color(0xFF64748B),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101417),
        surface: const Color(0xFF171C20),
        cardColor: const Color(0xFF1E252B),
        fieldColor: const Color(0xFF24303A),
      );
    case MedicoHubThemePreset.custom:
      final seed = safeThemeSeedColor(config.customSeedHex);
      final dark = config.customDarkMode;
      return _buildTheme(
        seed: seed,
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: dark
            ? _tint(seed, 0.08)
            : _mix(seed, Colors.white, 0.90),
        surface: dark ? _tint(seed, 0.16) : _mix(seed, Colors.white, 0.97),
        cardColor: dark ? _tint(seed, 0.20) : _mix(seed, Colors.white, 0.94),
        fieldColor: dark ? _tint(seed, 0.28) : _mix(seed, Colors.white, 0.84),
      );
  }
}

String normalizeHexColor(String raw) {
  final cleaned = raw.trim().replaceAll('#', '').toUpperCase();
  final hexPattern = RegExp(r'^[0-9A-F]+$');
  if ((cleaned.length == 6 || cleaned.length == 8) &&
      hexPattern.hasMatch(cleaned)) {
    return '#$cleaned';
  }
  return '';
}

Color? parseHexColor(String raw) {
  final normalized = normalizeHexColor(raw);
  if (normalized.isEmpty) {
    return null;
  }
  try {
    final value = normalized.substring(1);
    final buffer = StringBuffer();
    if (value.length == 6) {
      buffer.write('FF');
    }
    buffer.write(value);
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return null;
  }
}

Color safeThemeSeedColor(String raw) {
  return parseHexColor(raw) ?? const Color(0xFF4F8C73);
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

Color _mix(Color a, Color b, double amount) {
  final clamped = amount.clamp(0.0, 1.0);
  return Color.lerp(a, b, clamped) ?? a;
}

Color _tint(Color seed, double amount) {
  return _mix(seed, Colors.black, amount);
}
