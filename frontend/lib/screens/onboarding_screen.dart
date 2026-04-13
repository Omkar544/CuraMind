import 'package:flutter/material.dart';
import 'package:curamind/screens/login_page.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Track your mind',
      'description':
          'Understand your emotions and mood patterns over time with easy journaling.',
      'image': 'assets/images/onboarding1.jpg',
    },
    {
      'title': 'Stay healthy',
      'description':
          'Keep up with your fitness goals and medication schedules in one place.',
      'image': 'assets/images/onboarding2.jpg',
    },
    {
      'title': 'Get guidance',
      'description':
          'Receive personalized tips and insights to improve your overall well-being.',
      'image': 'assets/images/onboarding3.jpg',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Skip button for better UX
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child:
                      const Text("Skip", style: TextStyle(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(onboardingData[index]);
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingData.length,
                  (index) => _buildDot(index: index),
                ),
              ),
              const SizedBox(height: 40),
              // Dynamic CTA Button
              CustomButton(
                text: _currentPage == onboardingData.length - 1
                    ? "Get Started"
                    : "Next",
                onPressed: () {
                  if (_currentPage < onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // Final navigation to Login
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Using an Icon fallback if the local asset is missing during development
        Image.asset(
          data['image']!,
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.spa_rounded,
              size: 150,
              color: AppColors.primaryTeal,
            );
          },
        ),
        const SizedBox(height: 48),
        Text(
          data['title']!,
          style: AppStyles.headingStyle
              .copyWith(fontSize: 28, color: AppColors.primaryTeal),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            data['description']!,
            style: AppStyles.bodyStyle
                .copyWith(color: AppColors.textGrey, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryTeal
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}
