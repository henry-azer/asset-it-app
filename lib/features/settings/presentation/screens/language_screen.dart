import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/localization/language_provider.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:provider/provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

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
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildLanguageOption(
                        context,
                        isDark,
                        languageProvider,
                        'en',
                        'English',
                        '🇺🇸',
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                        context,
                        isDark,
                        languageProvider,
                        'ar',
                        'العربية',
                        '🇸🇦',
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
                  AppStrings.language.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.selectLanguageSubtitle.tr,
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

  Widget _buildLanguageOption(
    BuildContext context,
    bool isDark,
    LanguageProvider languageProvider,
    String languageCode,
    String languageName,
    String flag,
  ) {
    final isSelected = languageProvider.currentLanguageCode == languageCode;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        languageProvider.changeLanguage(languageCode);
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
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                languageName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blue.shade600
                          : null,
                    ),
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
