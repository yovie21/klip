import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xff101116);
  static const surface = Color(0xff1d1e25);
  static const muted = Color(0xff9698a4);
  static const accent = Color(0xffa7f432);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
      );
}
