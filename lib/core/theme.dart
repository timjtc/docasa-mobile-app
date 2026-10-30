import 'package:flutter/material.dart';

/// App theme — dark, cyan-accented, echoing the device LCD (dark blue
/// background `0x0821`, cyan boot accents).
abstract final class DocasaTheme {
  static const scaffoldBg = Color(0xFF0A1622);
  static const cardBg = Color(0xFF132233);
  static const accent = Color(0xFF26C6DA);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(surface: cardBg);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        indicatorColor: accent.withValues(alpha: 0.25),
      ),
      cardTheme: const CardThemeData(color: cardBg, margin: EdgeInsets.zero),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
