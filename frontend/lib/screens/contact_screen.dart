import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Contact Us", style: AppStyles.headingStyle),
          const SizedBox(height: 16),
          Text(
            "If you have any questions or feedback, feel free to reach out to us.",
            style: AppStyles.bodyStyle,
          ),
          const SizedBox(height: 24),
          _buildContactCard(
            icon: Icons.email_rounded,
            title: "Email",
            info: "support@curamind.com",
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.phone_rounded,
            title: "Phone",
            info: "+91 98765 43210",
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String info,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: AppColors.primaryTeal),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.subHeadingStyle),
              Text(info, style: AppStyles.bodyStyle),
            ],
          ),
        ],
      ),
    );
  }
}
