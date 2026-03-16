import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accent Colors
  static const Color primaryTeal = Color(0xFF008080); // Your main brand color
  static const Color primaryGreen = Color(0xFF4CAF50); // Another primary/accent
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color secondaryRed = Color(0xFFF44336);

  // Text Colors
  static const Color textDark =
      Color(0xFF333333); // Main dark text for readability
  static const Color textLight =
      Color(0xFF6C7A89); // Secondary light text (e.g., subtitles, hints)
  static const Color textGrey =
      Color(0xFFB0BEC5); // Lighter grey text, often for placeholder or disabled
  static const Color textLightest =
      Color(0xFFFFFFFF); // White text, good for buttons

  // Background Colors
  static const Color backgroundLight =
      Color(0xFFF0F0F0); // A very light grey for main backgrounds
  static const Color backgroundMedium =
      Color(0xFFE0E0E0); // For chart grids/light backgrounds/borders
  static const Color backgroundDark =
      Color(0xFF2C3E50); // Dark background for contrast or specific sections

  // Border & Error Colors
  static const Color borderLight =
      Color(0xFFD3DCE0); // Light border color for input fields etc.
  static const Color errorRed =
      Color(0xFFD32F2F); // Standard red for error messages

  // Icon Colors
  static const Color iconColor = Color(0xFF8D8D8D); // Default icon color
  static const Color textHint =
      Color(0xFFB0BEC5); // Hint text color (often same as textGrey)

  // Custom DailyMoves Colors (if needed, based on typical UI for such features)
  static const Color secondaryYellow =
      Color(0xFFFFF9C4); // Lighter yellow for specific UI elements
  static const Color secondaryCoral =
      Color(0xFFFFCCBC); // Lighter coral for XAI box

  // --- ADDED ALIASES FOR LIFELOG ---
  static const Color primaryColor = primaryTeal;
  static const Color bgColor = backgroundLight;
  static const Color textColor = textDark;
  static const Color buttonColor = primaryTeal;
  static const Color accentColor = accentBlue;
}
