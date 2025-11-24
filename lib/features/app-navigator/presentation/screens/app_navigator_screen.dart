import 'package:asset_it/features/assets/presentation/screens/assets_manager_screen.dart';
import 'package:asset_it/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:asset_it/features/finance/screens/finance_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/themes/theme_provider.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/app-navigator/presentation/providers/navigation_provider.dart';
import 'package:asset_it/features/settings/presentation/screens/settings_screen.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:provider/provider.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';

class AppNavigatorScreen extends StatefulWidget {
  const AppNavigatorScreen({super.key});

  @override
  State<AppNavigatorScreen> createState() => _AppNavigatorScreenState();
}

class _AppNavigatorScreenState extends State<AppNavigatorScreen> with WidgetsBindingObserver {

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AssetsManagerScreen(),
    const FinanceManagerScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFinanceData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFinanceData();
    }
  }

  Future<void> _refreshFinanceData() async {
    final currencyChoiceProvider = Provider.of<CurrencyChoiceProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    if (currencyChoiceProvider.hasCurrencyChoices) {
      await financeProvider.loadFinances();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, ThemeProvider>(
      builder: (context, navigationProvider, themeProvider, child) {
        return Scaffold(
          body: PageView(
            controller: navigationProvider.pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: navigationProvider.onPageChanged,
            children: _screens,
          ),
          bottomNavigationBar: SlidingClippedNavBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onButtonPressed: navigationProvider.setSelectedIndex,
            iconSize: 30,
            activeColor: Theme.of(context).colorScheme.primary,
            selectedIndex: navigationProvider.selectedIndex,
            barItems: [
              BarItem(
                icon: Icons.lock,
                title: AppStrings.dashboard.tr,
              ),
              BarItem(
                icon: Icons.account_balance_wallet,
                title: AppStrings.assets.tr,
              ),
              BarItem(
                icon: Icons.price_check,
                title: AppStrings.finance.tr,
              ),
              BarItem(
                icon: Icons.settings,
                title: AppStrings.settings.tr,
              ),
            ],
          ),
        );
      },
    );
  }
}
