import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

// --- Screen Imports ---
import 'package:curamind/screens/home_screen.dart';
import 'package:curamind/screens/login_page.dart';
import 'package:curamind/screens/mindease_screen.dart';
import 'package:curamind/screens/dailymoves_screen.dart';
import 'package:curamind/screens/lifelog_screen.dart';
import 'package:curamind/screens/about_screen.dart';
import 'package:curamind/screens/appointment_book_screen.dart';
import 'package:curamind/screens/talkbuddy_screen.dart';
import 'package:curamind/screens/settings_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  String _userName = 'User';
  String _currentTitle = 'Home';
  Widget _currentScreen = const HomeScreen();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  /// 👤 Load user identity from local storage for the greeting
  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
      });
    }
  }

  /// 🧭 Handles screen switching from the side drawer
  void _navigateTo(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
    Navigator.pop(context); // Close the drawer
  }

  /// 🔐 Clear session data and redirect to login
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_id');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content:
              const Text('Are you sure you want to end your wellness session?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textGrey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clean up display name (e.g., if user logged in with email)
    String displayName =
        _userName.contains('@') ? _userName.split('@').first : _userName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, $displayName',
          style: AppStyles.headingStyle.copyWith(fontSize: 20),
        ),
        centerTitle: false,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(LucideIcons.menu, color: AppColors.iconColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: "Navigation Menu",
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut,
                color: AppColors.errorRed, size: 20),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.backgroundLight,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryTeal, Color(0xFF006D77)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(LucideIcons.user,
                        size: 36, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hello, $displayName',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Your wellbeing companion',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(LucideIcons.home, 'Home', const HomeScreen()),
            _buildDrawerItem(
                LucideIcons.brain, 'Mental Health', const MindEaseScreen()),
            _buildDrawerItem(LucideIcons.flame, 'Fitness Tracking',
                const DailyMovesScreen()),
            _buildDrawerItem(LucideIcons.clipboardList, 'LifeLog Hub',
                const LifelogScreen()),
            _buildDrawerItem(LucideIcons.calendarClock, 'Appointment Book',
                const AppointmentBookScreen()),
            _buildDrawerItem(LucideIcons.messageCircle, 'TalkBuddy AI',
                const TalkbuddyScreen()),
            _buildDrawerItem(
                LucideIcons.sparkles, 'Motivation', const AboutScreen()),
            const Divider(indent: 20, endIndent: 20),
            _buildDrawerItem(LucideIcons.settings, 'Profile & Settings',
                const SettingsPage()),
            ListTile(
              leading:
                  const Icon(LucideIcons.logOut, color: AppColors.errorRed),
              title: Text(
                'Logout',
                style: AppStyles.bodyStyle.copyWith(
                    color: AppColors.errorRed, fontWeight: FontWeight.w600),
              ),
              onTap: _showLogoutConfirmationDialog,
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentScreen,
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget targetScreen) {
    // Check if the current screen matches the target to highlight the active tab
    final bool isSelected =
        _currentScreen.runtimeType == targetScreen.runtimeType;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryTeal : AppColors.iconColor,
        size: 22,
      ),
      title: Text(
        title,
        style: AppStyles.bodyStyle.copyWith(
          color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      onTap: () => _navigateTo(targetScreen, title),
      selected: isSelected,
      selectedTileColor: AppColors.primaryTeal.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
