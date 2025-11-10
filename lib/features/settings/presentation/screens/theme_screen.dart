import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/themes/theme_provider.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:provider/provider.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildThemeOption(
                        context,
                        isDark,
                        themeProvider,
                        ThemeMode.system,
                        Icons.brightness_auto,
                        AppStrings.themeSystem.tr,
                        AppStrings.themeSystemDescription.tr,
                      ),
                      const SizedBox(height: 12),
                      _buildThemeOption(
                        context,
                        isDark,
                        themeProvider,
                        ThemeMode.light,
                        Icons.light_mode,
                        AppStrings.themeLight.tr,
                        AppStrings.themeLightDescription.tr,
                      ),
                      const SizedBox(height: 12),
                      _buildThemeOption(
                        context,
                        isDark,
                        themeProvider,
                        ThemeMode.dark,
                        Icons.dark_mode,
                        AppStrings.themeDark.tr,
                        AppStrings.themeDarkDescription.tr,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.theme.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.chooseAppearance.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
    ThemeMode mode,
    IconData icon,
    String title,
    String description,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        themeProvider.setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      )
                    : null,
                color: isSelected ? null : (isDark ? const Color(0xFF0F1329) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? Colors.blue.shade600
                              : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.blue.shade600,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
