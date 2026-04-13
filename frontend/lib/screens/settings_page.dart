import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:curamind/utils/app_colors.dart';
import 'package:curamind/utils/app_styles.dart';
import 'package:curamind/services/user_management.dart'; // Integrated for cleanup features

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryTeal.withOpacity(0.2),
                          width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryTeal,
                      child:
                          Icon(LucideIcons.user, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Settings & Profile',
                    style: AppStyles.headingStyle
                        .copyWith(color: AppColors.primaryTeal, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your wellness account and preferences.',
                    style: AppStyles.bodyStyle
                        .copyWith(color: AppColors.textGrey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            _buildSectionLabel("Preferences"),

            // --- Settings Options ---
            // FIXED: Changed LucideIcons.userEdit to LucideIcons.user to resolve "Member not found" error
            _buildSettingsTile(
              icon: LucideIcons.user,
              title: 'Edit Profile',
              onTap: () => _showComingSoon(context, "Profile Editor"),
            ),
            _buildSettingsTile(
              icon: LucideIcons.bell,
              title: 'Notification Settings',
              onTap: () => _showComingSoon(context, "Notifications"),
            ),
            _buildSettingsTile(
              icon: LucideIcons.shieldCheck,
              title: 'Privacy & Security',
              onTap: () => _showComingSoon(context, "Privacy Panel"),
            ),

            const SizedBox(height: 32),
            _buildSectionLabel("Account Actions"),

            // --- Dangerous Actions ---
            _buildSettingsTile(
              icon: LucideIcons.trash2,
              title: 'Clear Data & Delete Account',
              titleColor: AppColors.errorRed,
              iconColor: AppColors.errorRed,
              onTap: () => _showDeleteConfirmation(context),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'Logout is available via the side menu.',
                style: AppStyles.bodyStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textGrey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading:
            Icon(icon, color: iconColor ?? AppColors.primaryTeal, size: 22),
        title: Text(
          title,
          style: AppStyles.bodyStyle.copyWith(
            color: titleColor ?? AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing:
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming in the next AI update!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Account?"),
        content: const Text(
          "This will wipe all your data from PostgreSQL and MongoDB. This action is permanent.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              // FIXED: Successfully calling the UserManagementService to wipe the "Clean Slate"
              UserManagementService.deleteAccountAndClearCache(context);
            },
            child: const Text("Delete Everything"),
          ),
        ],
      ),
    );
  }
}
