import 'package:flutter/material.dart';

class AppThemeController {
  static final themeMode = ValueNotifier(ThemeMode.system);

  static void setDarkMode(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
