import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Text Styles — Bouslty brand type scale.
/// Alexandria for headlines, Readex Pro for text & interface.
/// Both are free Google Fonts with Arabic + Latin support.
class AppTextStyles {
  AppTextStyles._();

  // Readex Pro — all text, buttons and app interface.
  static TextStyle _base({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.readexPro(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Alexandria — headlines.
  static TextStyle _display({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.alexandria(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Headings
  static TextStyle h1({Color? color}) => _display(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle h2({Color? color}) => _display(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle h3({Color? color}) => _display(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle h4({Color? color}) => _display(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body text
  static TextStyle bodyLarge({Color? color}) => _base(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // Labels
  static TextStyle labelLarge({Color? color}) => _base(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => _base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => _base(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // Buttons
  static TextStyle buttonLarge({Color? color}) => _base(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle buttonMedium({Color? color}) => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle buttonSmall({Color? color}) => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
