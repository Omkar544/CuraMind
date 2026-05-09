import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import 'dart:math';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // =============================
  // ✅ Daily Changing Quote
  // =============================
  String getDailyQuote() {
    final quotes = [
      "Your health is your greatest wealth.",
      "Small daily improvements lead to stunning results.",
      "Take care of your body. It’s the only place you have to live.",
      "Healthy habits today, stronger tomorrow.",
      "Balance your mind. Strengthen your body.",
      "Every day is a new beginning for better health.",
    ];

    final dayIndex = DateTime.now().day % quotes.length;
    return quotes[dayIndex];
  }

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
            // =============================
            // 🌿 Daily Quote Section
            // =============================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppStyles.cardDecoration,
              child: Text(
                "“${getDailyQuote()}”",
                style: AppStyles.bodyStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =============================
            // 🎯 Mission
            // =============================
            Text(
              "Our Mission",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 8),
            Text(
              "CuraMind is dedicated to providing a friendly and accessible platform "
              "for tracking both mental and physical health. Our goal is to empower "
              "users with AI-driven insights and guidance to live a healthier, "
              "more balanced life.",
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textDark),
            ),

            const SizedBox(height: 30),

            // =============================
            // 🏫 College Info
            // =============================
            Text(
              "Institution",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 8),
            Text(
              "Dr. J J Magdum College Of Engineering, Jaysingpur",
              style: AppStyles.bodyStyle.copyWith(color: AppColors.textDark),
            ),

            const SizedBox(height: 30),

            // =============================
            // 👥 Project Team
            // =============================
            Text(
              "Project Team",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 16),

            _buildTeamCard("Frontend Team (IT Department)", [
              "Mr. Omkar Amit Gore (IT) - Roll No: 64",
              "Miss. Manali Sudhir Awale (IT) - Roll No: 65",
            ]),

            const SizedBox(height: 16),

            _buildTeamCard("Backend & AI Team (AI&DS Department)", [
              "Miss. Rutuja Satish Mahadik (AI&DS) - Roll No: 64",
              "Mr. Harshvardhan Mahesh Patil (AI&DS) - Roll No: 65",
            ]),

            const SizedBox(height: 30),

            // =============================
            // 🎓 Faculty Coordinators
            // =============================
            Text(
              "Under the Guidance Of",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 12),

            _buildTeamCard("Faculty Co-ordinators", [
              "Prof. J. T. Patil (IT Department)",
              "Prof. Mrs. P. A. Chougule (AI&DS Department)",
            ]),

            const SizedBox(height: 30),

            // =============================
            // 📞 Contact Section
            // =============================
            Text(
              "Contact",
              style: AppStyles.subHeadingStyle
                  .copyWith(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Phone: 7249864599",
                      style: AppStyles.bodyStyle
                          .copyWith(color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text("Email: ogore3414@gmail.com",
                      style: AppStyles.bodyStyle
                          .copyWith(color: AppColors.textDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================
  // 🔹 Reusable Card Builder
  // =============================
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
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                member,
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
