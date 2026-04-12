import 'package:flutter/material.dart';
import 'core/theme/app_theme_controller.dart';
import 'features/auth/change_password/change_password_page.dart';
import 'features/auth/forgot_password/forgot_password_page.dart';
import 'features/auth/login/login_page.dart';
import 'features/auth/register/register_page.dart';
import 'features/auth/reset_password/reset_password_page.dart';
import 'features/auth/resend_verification/resend_verification_page.dart';
import 'features/admin/screens/admin_page.dart';
import 'features/student/screens/academy_info_page.dart';
import 'features/student/screens/checkin_calendar_page.dart';
import 'features/student/screens/academy_schedule_calendar_page.dart';
import 'features/student/screens/home_page.dart';
import 'features/student/screens/profile_page.dart';
import 'features/student/screens/athletes_page.dart';
import 'features/student/screens/birthdays_page.dart';
import 'features/student/screens/feed_page.dart';
import 'features/student/screens/settings_page.dart';
import 'features/student/screens/complete_profile_page.dart';
import 'features/marketplace/screens/marketplace_page.dart';
import 'features/dashboard/screens/academy_dashboard_page.dart';
import 'features/dashboard/screens/sales_dashboard_page.dart';
import 'features/dashboard/screens/analytics_dashboard_page.dart';
import 'features/training/screens/gamification_page.dart';
import 'features/training/screens/ranking_page.dart';
import 'features/training/screens/graduation_schedule_page.dart';
import 'features/gyms/screens/gym_select_page.dart';
import 'shared/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'MeuCT',
          theme: buildAppLightTheme(),
          darkTheme: buildAppDarkTheme(),
          themeMode: mode,
          builder: (context, child) => child ?? const SizedBox.shrink(),
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
            '/change-password': (context) => const ChangePasswordPage(),
            '/admin': (context) => const AdminPage(),
            '/resend-verification': (context) =>
                const ResendVerificationPage(),
            '/profile': (context) => const ProfilePage(),
            '/birthdays': (context) => const BirthdaysPage(),
            '/checkin': (context) => const CheckinCalendarPage(),
            '/schedule-calendar': (context) =>
                const AcademyScheduleCalendarPage(),
            '/academy-info': (context) => const AcademyInfoPage(),
            '/athletes': (context) => const AthletesPage(),
            '/feed': (context) => const FeedPage(),
            '/settings': (context) => const SettingsPage(),
            '/complete-profile': (context) =>
                const CompleteProfilePage(),
            '/home': (context) => const HomePage(),
            '/marketplace': (context) => const MarketplacePage(),
            '/dashboard-academy': (context) => const AcademyDashboardPage(),
            '/dashboard-sales': (context) => const SalesDashboardPage(),
            '/dashboard-analytics': (context) => const AnalyticsDashboardPage(),
            '/gamification': (context) => const GamificationPage(),
            '/ranking': (context) => const RankingPage(),
            '/graduation-schedule': (context) =>
                const GraduationSchedulePage(),
            '/select-gym': (context) => const GymSelectPage(
                  title: "Escolher academia",
                  barrierDismissible: true,
                ),
          },
        );
      },
    );
  }
}
