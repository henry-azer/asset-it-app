import 'package:asset_it/features/assets/presentation/screens/asset_screen.dart';
import 'package:asset_it/features/assets/presentation/screens/salaries_manager_screen.dart';
import 'package:asset_it/features/assets/presentation/screens/salary_screen.dart';
import 'package:asset_it/features/finance/screens/finance_manager_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/features/app-navigator/presentation/screens/app_navigator_screen.dart';
import 'package:asset_it/features/auth/presentation/screens/login_screen.dart';
import 'package:asset_it/features/auth/presentation/screens/register_screen.dart';
import 'package:asset_it/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/settings_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/theme_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/language_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/about_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/help_support_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/backup_export_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/backup_import_screen.dart';
import 'package:asset_it/features/finance/screens/currency_manager_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/rate_app_screen.dart';
import 'package:asset_it/features/settings/presentation/screens/bug_report_screen.dart';
import 'package:asset_it/features/finance/screens/finance_screen.dart';
import 'package:asset_it/features/splash/presentation/screens/splash_screen.dart';
import 'package:asset_it/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:asset_it/core/enums/finance_enums.dart';
import 'package:asset_it/data/entities/finance.dart';
import 'package:asset_it/data/entities/salary.dart';

class Routes {
  static const String initial = '/';

  static const String onboarding = '/onboarding';

  static const String login = '/auth/login';
  static const String register = '/auth/register';

  static const String app = '/app';

  static const String dashboard = '/app/dashboard';

  static const String assetManager = '/app/asset-manager';
  static const String asset = '/app/assets/asset';

  static const String financeManager = '/app/finance-manager';
  static const String finance = '/app/finance-manager/finance';

  static const String currencyManager = '/app/currency-manager';
  static const String currency = '/app/currency-manager/currency';

  static const String salaryManager = '/app/salary-manager';
  static const String salary = '/app/salary-manager/salary';

  static const String settings = '/app/settings';
  static const String userProfile = '/app/settings/profile';

  static const String theme = '/app/settings/theme';
  static const String language = '/app/settings/language';

  static const String backupExport = '/app/settings/backup/export';
  static const String backupImport = '/app/settings/backup/import';

  static const String rateApp = '/app/settings/rate';
  static const String helpSupport = '/app/settings/help';
  static const String bugReport = '/app/settings/bug-report';

  static const String about = '/app/settings/about';
}

class AppRoutes {
  static Route? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.initial:
        return MaterialPageRoute(
            builder: (context) {
              return const SplashScreen();
            },
            settings: routeSettings);

      case Routes.onboarding:
        return MaterialPageRoute(
            builder: (context) {
              return const OnboardingScreen();
            },
            settings: routeSettings);

      case Routes.login:
        return MaterialPageRoute(
            builder: (context) {
              return const LoginScreen();
            },
            settings: routeSettings);

      case Routes.register:
        return MaterialPageRoute(
            builder: (context) {
              return const RegisterScreen();
            },
            settings: routeSettings);

      case Routes.app:
        return MaterialPageRoute(
            builder: (context) {
              return const AppNavigatorScreen();
            },
            settings: routeSettings);

      case Routes.dashboard:
        return MaterialPageRoute(
            builder: (context) {
              return const DashboardScreen();
            },
            settings: routeSettings);

      case Routes.asset:
        final asset = routeSettings.arguments as Asset?;
        return MaterialPageRoute(
            builder: (context) {
              return AssetScreen(assetToEdit: asset);
            },
            settings: routeSettings);

      case Routes.settings:
        return MaterialPageRoute(
            builder: (context) {
              return const SettingsScreen();
            },
            settings: routeSettings);

      case Routes.userProfile:
        return MaterialPageRoute(
            builder: (context) {
              return const UserProfileScreen();
            },
            settings: routeSettings);

      case Routes.theme:
        return MaterialPageRoute(
            builder: (context) {
              return const ThemeScreen();
            },
            settings: routeSettings);

      case Routes.language:
        return MaterialPageRoute(
            builder: (context) {
              return const LanguageScreen();
            },
            settings: routeSettings);

      case Routes.about:
        return MaterialPageRoute(
            builder: (context) {
              return const AboutScreen();
            },
            settings: routeSettings);

      case Routes.helpSupport:
        return MaterialPageRoute(
            builder: (context) {
              return const HelpSupportScreen();
            },
            settings: routeSettings);

      case Routes.backupExport:
        return MaterialPageRoute(
            builder: (context) {
              return const BackupExportScreen();
            },
            settings: routeSettings);

      case Routes.backupImport:
        return MaterialPageRoute(
            builder: (context) {
              return const BackupImportScreen();
            },
            settings: routeSettings);

      case Routes.currencyManager:
        return MaterialPageRoute(
            builder: (context) {
              return const CurrencyManagerScreen();
            },
            settings: routeSettings);

      case Routes.rateApp:
        return MaterialPageRoute(
            builder: (context) {
              return const RateAppScreen();
            },
            settings: routeSettings);

      case Routes.bugReport:
        return MaterialPageRoute(
            builder: (context) {
              return const BugReportScreen();
            },
            settings: routeSettings);

      case Routes.financeManager:
        return MaterialPageRoute(
          builder: (context) => const FinanceManagerScreen(),
        );

      case Routes.finance:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final financeType =
            args?['type'] as FinanceType? ?? FinanceType.currency;
        final finance = args?['finance'] as Finance?;
        return MaterialPageRoute(
          builder: (context) => FinanceScreen(
            financeType: financeType,
            finance: finance,
          ),
        );

      case Routes.salaryManager:
        return MaterialPageRoute(
          builder: (context) => const SalariesManagerScreen(),
        );

      case Routes.salary:
        final salary = routeSettings.arguments as Salary?;
        return MaterialPageRoute(
          builder: (context) => SalaryScreen(salaryToEdit: salary),
        );

      default:
        return undefinedRoute();
    }
  }

  static Route<dynamic> undefinedRoute() {
    return MaterialPageRoute(
        builder: ((context) => const Scaffold(
              body: Center(
                child: Text(AppStrings.noRouteFound),
              ),
            )));
  }
}
