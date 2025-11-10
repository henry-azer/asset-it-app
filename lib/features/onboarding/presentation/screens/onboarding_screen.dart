import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/core/utils/app_assets_manager.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  late final List<OnboardingPage> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OnboardingPage(
        title: AppStrings.onboardingTitle1.tr,
        description: AppStrings.onboardingDesc1.tr,
        image: AppImageAssets.onboarding1,
      ),
      OnboardingPage(
        title: AppStrings.onboardingTitle2.tr,
        description: AppStrings.onboardingDesc2.tr,
        image: AppImageAssets.onboarding2,
      ),
      OnboardingPage(
        title: AppStrings.onboardingTitle3.tr,
        description: AppStrings.onboardingDesc3.tr,
        image: AppImageAssets.onboarding3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
          title: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              AppStrings.appName.tr.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          )),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  Provider.of<OnboardingProvider>(context, listen: false)
                      .setCurrentPage(index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Image.asset(
            page.image,
            height: 200,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Consumer<OnboardingProvider>(
      builder: (context, onboardingProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: onboardingProvider.currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: onboardingProvider.currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (onboardingProvider.currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(AppStrings.back.tr),
                    ),
                  const Spacer(),
                  if (onboardingProvider.currentPage == _pages.length - 1)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          AppStrings.getStarted.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          AppStrings.next.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeOnboarding() async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.register);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}
