// frontend/lib/widgets/custom_button.dart
import 'package:flutter/material.dart';
import 'package:curamind/utils/app_colors.dart';
import 'package:curamind/utils/app_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // <--- Make onPressed nullable
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed, // <--- Keep it required, but now it can be null
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // This is now fine as onPressed can be null
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ??
            AppColors.primaryTeal, // Assuming primaryTeal is your default
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        text,
        style: textStyle ?? AppStyles.buttonTextStyle,
      ),
    );
  }
}
