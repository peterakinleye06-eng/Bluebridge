import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey.shade100,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.blue,
    ),
    cardTheme: const CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
