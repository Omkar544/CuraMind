import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- SERVICE IMPORTS ---
import 'package:curamind/services/notification_service.dart'; // <--- ADDED THIS

// --- SCREEN IMPORTS ---
import 'package:curamind/screens/login_page.dart';
import 'package:curamind/screens/register_page.dart';
import 'package:curamind/screens/main_wrapper.dart';
import 'package:curamind/screens/onboarding_screen.dart';
import 'package:curamind/utils/app_colors.dart';
import 'package:curamind/utils/app_styles.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize the Notification Service from the Canvas
  // This is required for the CareClock "ringing" feature to function
  await NotificationService().init();

  // 3. Setup System UI overlay for a clean look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // 4. Check user session
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getString('auth_token') != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// A simple loading screen to act as an initial placeholder
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryTeal),
            SizedBox(height: 20),
            Text(
              'Loading CuraMind...',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    // Determine the starting point based on login status
    String initialRouteName = isLoggedIn ? '/main_wrapper' : '/onboarding';

    return MaterialApp(
      title: 'CuraMind',
      debugShowCheckedModeBanner: false,
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
              fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: AppColors.iconColor),
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppStyles.buttonTextStyle,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryTeal,
            textStyle:
                AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/login':
            builder = (BuildContext _) => const LoginPage();
            break;
          case '/register':
            builder = (BuildContext _) => const RegisterPage();
            break;
          case '/main_wrapper':
            builder = (BuildContext _) => const MainWrapper();
            break;
          case '/onboarding':
            builder = (BuildContext _) => const OnboardingScreen();
            break;
          default:
            debugPrint(
                'Attempted to navigate to unknown route: ${settings.name}. Redirecting to initial fallback: $initialRouteName');
            return MaterialPageRoute(
                builder: (context) =>
                    _buildInitialRoute(context, initialRouteName));
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
      // Ensures the LoadingScreen shows briefly during the initial transition
      onGenerateInitialRoutes: (String initialRoute) {
        return [
          MaterialPageRoute(builder: (context) => const LoadingScreen()),
          MaterialPageRoute(
              builder: (context) =>
                  _buildInitialRoute(context, initialRouteName)),
        ];
      },
    );
  }

  Widget _buildInitialRoute(BuildContext context, String routeName) {
    switch (routeName) {
      case '/login':
        return const LoginPage();
      case '/register':
        return const RegisterPage();
      case '/main_wrapper':
        return const MainWrapper();
      case '/onboarding':
        return const OnboardingScreen();
      default:
        return const LoginPage();
    }
  }
}
