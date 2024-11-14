// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  cardColor: const Color(0xFFE2F4FF),
  colorScheme: const ColorScheme.light(
    background: Colors.white,
    primary: Color(0xFFF5F5F5),
    secondary: Colors.red,
  ),
  //Text
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    labelLarge: TextStyle(color: Colors.black),
  ),
  //Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(
          const Color.fromARGB(255, 109, 109, 110)),
      elevation: MaterialStateProperty.all(0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      minimumSize: MaterialStateProperty.all(const Size(100, 50)),
    ),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  cardColor: const Color(0xFF0C4769),
  colorScheme: const ColorScheme.dark(
    background: Color.fromARGB(255, 39, 42, 47),
    primary: Color(0xFF323943),
    secondary: Color(0x323943),
  ),
  //Text
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    labelLarge: TextStyle(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          MaterialStateProperty.all<Color>(const Color(0xFF323943)),
      elevation: MaterialStateProperty.all(0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      minimumSize: MaterialStateProperty.all(const Size(100, 50)),
    ),
  ),
);
