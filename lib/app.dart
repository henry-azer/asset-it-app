import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/localization/language_provider.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/config/themes/app_theme.dart';
import 'package:asset_it/config/themes/theme_provider.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/app-navigator/presentation/providers/navigation_provider.dart';
import 'package:asset_it/features/auth/presentation/providers/auth_provider.dart';
import 'package:asset_it/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:asset_it/features/settings/presentation/providers/biometric_provider.dart';
import 'package:asset_it/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:asset_it/features/assets/presentation/providers/assets_provider.dart';
import 'package:asset_it/features/assets/presentation/providers/salary_provider.dart';
import 'package:asset_it/features/finance/providers/asset_settings_provider.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/injection_container.dart';
import 'package:provider/provider.dart';

class AssetItApp extends StatelessWidget {
  const AssetItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyChoiceProvider(sl())),
        ChangeNotifierProxyProvider<CurrencyChoiceProvider, FinanceProvider>(
          create: (context) => FinanceProvider(
            sl(),
            context.read<CurrencyChoiceProvider>(),
          ),
          update: (context, currencyChoiceProvider, previous) => 
            previous ?? FinanceProvider(sl(), currencyChoiceProvider),
        ),
        ChangeNotifierProxyProvider2<FinanceProvider, CurrencyChoiceProvider, AssetsProvider>(
          create: (context) => AssetsProvider(
            financeProvider: context.read<FinanceProvider>(),
            currencyChoiceProvider: context.read<CurrencyChoiceProvider>(),
          ),
          update: (context, financeProvider, currencyChoiceProvider, previous) => 
            previous ?? AssetsProvider(
              financeProvider: financeProvider,
              currencyChoiceProvider: currencyChoiceProvider,
            ),
        ),
        ChangeNotifierProvider(create: (_) => AssetSettingsProvider()),
        ChangeNotifierProxyProvider<CurrencyChoiceProvider, SalaryProvider>(
          create: (context) => SalaryProvider(
            sl(),
            context.read<CurrencyChoiceProvider>(),
          ),
          update: (context, currencyChoiceProvider, previous) => 
            previous ?? SalaryProvider(sl(), currencyChoiceProvider),
        ),
      ],
      builder: (context, child) {
        _removeSplash();
        return Consumer2<ThemeProvider, LanguageProvider>(
          builder: (context, themeProvider, languageProvider, child) {
            return Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return MaterialApp(
                  title: AppStrings.appName.tr,
                  locale: languageProvider.currentLocale,
                  debugShowCheckedModeBanner: false,
                  theme: appTheme(),
                  darkTheme: appDarkTheme(),
                  themeMode: themeProvider.themeMode,
                  onGenerateRoute: AppRoutes.onGenerateRoute,
                  supportedLocales: languageProvider.availableLanguagesLocales,
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  localeResolutionCallback: (locale, supportedLocales) {
                    for (var supportedLocale in supportedLocales) {
                      if (supportedLocale.languageCode == locale?.languageCode) {
                        return supportedLocale;
                      }
                    }
                    return supportedLocales.first;
                  },

                  builder: (context, child) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    final overlayStyle = SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness:
                          isDark ? Brightness.light : Brightness.dark,
                      statusBarBrightness:
                          isDark ? Brightness.light : Brightness.dark,
                      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
                      systemNavigationBarIconBrightness:
                          isDark ? Brightness.light : Brightness.dark,
                      systemNavigationBarDividerColor: Theme.of(context).scaffoldBackgroundColor
                    );

                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: overlayStyle,
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _removeSplash() async {
    await Future.delayed(const Duration(seconds: 1));
    FlutterNativeSplash.remove();
  }
}
