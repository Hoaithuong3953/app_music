import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    primaryColor: Color(0xFFBBDEFB), // Xanh tím nhạt
    scaffoldBackgroundColor: Color(0xFFF5F5F5), // Nền xám nhạt
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Color(0xFF90CAF9), // Accent: Xanh nhạt hơn
    ),
    highlightColor: Color(0xFF0288D1), // Màu đậm hơn để nhấn mạnh
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28, // Sẽ được điều chỉnh động trong widget
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16, // Sẽ được điều chỉnh động
        color: Color(0xFF212121),
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14, // Sẽ được điều chỉnh động
        color: Color(0xFF212121),
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12, // Sẽ được điều chỉnh động
        color: Colors.grey[600],
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFBBDEFB),
        foregroundColor: Color(0xFF212121),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF212121)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFBBDEFB), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF212121)),
      ),
      prefixIconColor: Colors.grey,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFFF5F5F5),
      foregroundColor: Color(0xFF212121),
    ),
  );
}