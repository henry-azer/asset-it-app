import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/core/utils/app_assets_manager.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isUserOnboarded = await authProvider.isUserOnboarded();
    final isUserCreated = await authProvider.isUserCreated();

    if (!mounted) return;

    if (!isUserOnboarded) {
      Navigator.pushReplacementNamed(context, Routes.onboarding);
    } else {
      if (!isUserCreated) {
        Navigator.pushReplacementNamed(context, Routes.register);
      } else {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? AppImageAssets.darkLogo
                    : AppImageAssets.lightLogo,
                height: 220,
                width: 350,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Text(
                AppStrings.appName.tr.toUpperCase(),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.08,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
