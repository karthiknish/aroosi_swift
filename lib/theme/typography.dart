import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
   // Headings: use Boldonse for display/title styles
  static TextStyle get h1 => const TextStyle(
    fontFamily: 'Boldonse',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  static TextStyle get h2 => const TextStyle(
    fontFamily: 'Boldonse',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  static TextStyle get h3 => const TextStyle(
    fontFamily: 'Boldonse',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  // Body: keep Nunito Sans via GoogleFonts for parity
  static TextStyle get body => GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.45,
  );

  static TextStyle get bodyMedium => GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.45,
  );

  static TextStyle get bodySemiBold => GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.45,
  );

  static TextStyle get bodyBold => GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.45,
  );

  static TextStyle get caption => GoogleFonts.nunitoSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.3,
  );

  static TextStyle get captionMedium => GoogleFonts.nunitoSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.3,
  );
}
