import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

// Import all screens for navigation
import 'package:curamind/screens/mindease_screen.dart';
import 'package:curamind/screens/dailymoves_screen.dart';
import 'package:curamind/screens/lifelog_screen.dart';
import 'package:curamind/screens/about_screen.dart';
import 'package:curamind/screens/appointment_book_screen.dart';
import 'package:curamind/screens/talkbuddy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickAccessSection(context),
          const SizedBox(height: 24),
          _buildWellnessInsightCard(),
          const SizedBox(height: 24),
          _buildDailyGoalSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primaryTeal.withOpacity(0.2), width: 2),
          ),
          child: const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryTeal,
            child: Icon(LucideIcons.user, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $_userName!', style: AppStyles.subHeadingStyle),
            Text('Your AI health journey continues.',
                style: AppStyles.bodyStyle
                    .copyWith(color: AppColors.textGrey, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildQuickAccessGrid(context),
      ],
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    final Map<String, Widget> navigationMap = {
      'Mental Health': const MindEaseScreen(),
      'Fitness': const DailyMovesScreen(),
      'LifeLog Hub': const LifelogScreen(),
      'TalkBuddy': const TalkbuddyScreen(),
      'Appointments': const AppointmentBookScreen(),
      'Motivation': const AboutScreen(),
    };

    final List<Map<String, dynamic>> items = [
      {
        'title': 'Mental Health',
        'icon': LucideIcons.smile,
        'color': AppColors.primaryTeal
      },
      {
        'title': 'Fitness',
        'icon': LucideIcons.flame,
        'color': AppColors.accentBlue
      },
      {
        'title': 'LifeLog Hub',
        'icon': LucideIcons.clipboardList,
        'color': AppColors.primaryOrange
      },
      {
        'title': 'TalkBuddy',
        'icon': LucideIcons.messageSquare,
        'color': AppColors.primaryGreen
      },
      {
        'title': 'Appointments',
        'icon': LucideIcons.calendarDays,
        'color': AppColors.secondaryRed
      },
      {
        'title': 'Motivation',
        'icon': LucideIcons.zap,
        'color': AppColors.accentYellow
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (c) => navigationMap[item['title']]!)),
          child: Container(
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20.0),
              border:
                  Border.all(color: (item['color'] as Color).withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item['icon'], size: 24, color: item['color']),
                Text(
                  item['title'],
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWellnessInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: AppColors.accentYellow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.sparkles,
                  color: AppColors.accentYellow, size: 20),
              const SizedBox(width: 8),
              Text('DAILY INSIGHT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Personalized tips are waiting!',
              style: AppStyles.subHeadingStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
              'Sync your Fitbit data in "Fitness" to see AI-driven wellness recommendations tailored to your activity.',
              textAlign: TextAlign.center,
              style: AppStyles.bodyStyle
                  .copyWith(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDailyGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Focus',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryTeal.withOpacity(0.1),
                AppColors.primaryTeal.withOpacity(0.05)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryTeal.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.checkCircle2,
                  color: AppColors.primaryTeal, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MindEase Check-in',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Take 2 minutes to log your mood.',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ],
    );
  }
}
