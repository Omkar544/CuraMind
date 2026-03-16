// frontend/lib/widgets/talkbuddy_floating_button.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../screens/talkbuddy_screen.dart'; // Import the TalkbuddyScreen

class TalkBuddyFloatingButton extends StatelessWidget {
  const TalkBuddyFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24.0,
      right: 24.0,
      child: SizedBox(
        width: 70, // Increased size for the button
        height: 70, // Increased size for the button
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to the full TalkbuddyScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TalkbuddyScreen()),
            );
          },
          backgroundColor: AppColors.primaryTeal,
          heroTag:
              "talkbuddyBtn", // Add a unique heroTag if you have multiple FloatingActionButtons
          child: Image.asset('assets/logos/Curamind_chatbot.png', height: 40),
        ),
      ),
    );
  }
}
 