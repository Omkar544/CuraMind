import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- SERVICE IMPORTS ---
import 'package:curamind/services/notification_service.dart';

// --- SCREEN IMPORTS ---
import 'package:curamind/screens/login_page.dart';
import 'package:curamind/screens/register_page.dart';
import 'package:curamind/screens/main_wrapper.dart';
import 'package:curamind/screens/onboarding_screen.dart';
import 'package:curamind/utils/app_colors.dart';
import 'package:curamind/utils/app_styles.dart';

/// ✅ DARK MODE CONTROLLER
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getString('auth_token') != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'CuraMind',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          // ---------------- LIGHT THEME ----------------
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
            useMaterial3: true,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: AppColors.backgroundLight,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.backgroundLight,
              foregroundColor: AppColors.textDark,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: AppColors.backgroundLight,
                statusBarIconBrightness: Brightness.dark,
              ),
              titleTextStyle: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            inputDecorationTheme: AppStyles.inputDecorationTheme,
            textTheme: TextTheme(
              bodyLarge: AppStyles.bodyStyle,
              bodyMedium: AppStyles.bodyStyle.copyWith(fontSize: 14),
              headlineSmall: AppStyles.subHeadingStyle,
              headlineMedium: AppStyles.headingStyle,
              labelLarge: AppStyles.buttonTextStyle,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.textLightest,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: AppStyles.buttonTextStyle,
              ),
            ),
          ),

          // ---------------- DARK THEME ----------------
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryTeal,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Poppins',
          ),

          // ✅ SIMPLE & STABLE ROUTING
          initialRoute: isLoggedIn ? '/main_wrapper' : '/onboarding',

          routes: {
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/main_wrapper': (_) => const MainWrapper(),
            '/onboarding': (_) => const OnboardingScreen(),
          },
        );
      },
    );
  }
}
