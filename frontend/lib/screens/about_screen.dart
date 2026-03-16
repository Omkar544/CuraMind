import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text("About CuraMind",
            style: AppStyles.headingStyle.copyWith(color: AppColors.textDark)),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.iconColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Our Mission",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 8),
            Text(
              "CuraMind is dedicated to providing a friendly and accessible platform for tracking both mental and physical health. Our goal is to empower users with insights and guidance to live a healthier, more balanced life.",
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 24),
            Text(
              "Project Team",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 16),
            _buildTeamCard("Frontend Team", [
              // Now correctly defined below
              "Harshwardhan Patil",
              "Manali Awale",
            ]),
            const SizedBox(height: 16),
            _buildTeamCard("Backend Team", [
              // Now correctly defined below
              "Omkar Gore",
              "Rutuja Mahadik",
            ]),
          ],
        ),
      ),
    );
  }

  // --- Helper method is now INSIDE the AboutScreen class ---
  Widget _buildTeamCard(String title, List<String> members) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.bodyStyle.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          ...members.map((member) => Text(member,
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textDark))),
        ],
      ),
    );
  }
}
