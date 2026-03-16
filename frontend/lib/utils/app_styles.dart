import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // Heading Styles
  static final TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  static final TextStyle subHeadingStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // Body Styles
  static final TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  // Button Text Style
  static final TextStyle buttonTextStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textLightest, // White text for buttons
  );

  // Card Decoration
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white, // Or a specific color from AppColors
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Input Decoration for individual TextFormFields (used directly in LoginPage/RegisterPage)
  static const InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.backgroundLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.errorRed, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.errorRed, width: 2),
    ),
    labelStyle: TextStyle(color: AppColors.textHint),
    hintStyle: TextStyle(color: AppColors.textHint),
    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
  );

  // Input Decoration Theme (for global application in main.dart)
  static const InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.backgroundLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.errorRed, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.errorRed, width: 2),
    ),
    labelStyle: TextStyle(color: AppColors.textHint),
    hintStyle: TextStyle(color: AppColors.textHint),
    contentPadding:
        EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
  );

  // --- ADDED ALIASES FOR LIFELOG ---
  static final TextStyle textStyle = bodyStyle; // Alias for bodyStyle
  static final TextStyle headlineStyle1 =
      headingStyle; // Alias for headingStyle
  static final TextStyle headlineStyle2 =
      subHeadingStyle; // Alias for subHeadingStyle
  static final TextStyle headlineStyle3 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static final TextStyle headlineStyle4 = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );
}
