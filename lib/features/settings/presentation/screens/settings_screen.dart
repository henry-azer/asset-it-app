import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/localization/language_provider.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/config/themes/theme_provider.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/auth/presentation/providers/auth_provider.dart';
import 'package:asset_it/features/settings/presentation/providers/biometric_provider.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.userProfile);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.purple.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  child: Icon(Icons.person_outline)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authProvider.currentUser?.username ??
                                          AppStrings.user.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppStrings.member.tr,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.verified_user,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Consumer<BiometricProvider>(
                    builder: (context, biometricProvider, child) {
                      if (!biometricProvider.isBiometricAvailable) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(AppStrings.security.tr),
                          _buildSettingsTile(
                            icon: Icons.fingerprint,
                            title: biometricProvider.biometricTypeLabel,
                            subtitle: biometricProvider.isBiometricEnabled
                                ? AppStrings.biometricEnabled.tr
                                : AppStrings.biometricDisabled.tr,
                            trailing: Switch(
                              value: biometricProvider.isBiometricEnabled,
                              onChanged: (value) async {
                                final success = await biometricProvider.toggleBiometric(value);
                                if (!success && value && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppStrings.biometricAuthFailed.tr),
                                    ),
                                  );
                                }
                              },
                              activeColor: Colors.blue.shade400,
                              activeTrackColor: Colors.purple.shade300,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  _buildSectionHeader(AppStrings.appearance.tr),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildSettingsTile(
                        icon: Icons.brightness_6,
                        title: AppStrings.theme.tr,
                        subtitle: _getThemeText(themeProvider.themeMode),
                        onTap: () => Navigator.pushNamed(context, Routes.theme),
                      );
                    },
                  ),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return _buildSettingsTile(
                        icon: Icons.language,
                        title: AppStrings.language.tr,
                        subtitle: languageProvider.currentLanguageName,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.language),
                      );
                    },
                  ),
                  _buildSectionHeader(AppStrings.dataManagement.tr),
                  _buildSettingsTile(
                    icon: Icons.backup_outlined,
                    title: AppStrings.exportData.tr,
                    subtitle: AppStrings.exportDataSubtitle.tr,
                    onTap: () => Navigator.pushNamed(context, Routes.backupExport),
                  ),
                  _buildSettingsTile(
                    icon: Icons.restore_outlined,
                    title: AppStrings.importData.tr,
                    subtitle: AppStrings.importDataSubtitle.tr,
                    onTap: () => Navigator.pushNamed(context, Routes.backupImport),
                  ),
                  _buildSectionHeader(AppStrings.supportInformation.tr),
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: AppStrings.helpSupport.tr,
                    subtitle: AppStrings.helpSupportDescription.tr,
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.helpSupport),
                  ),
                  _buildSettingsTile(
                    icon: Icons.bug_report,
                    title: AppStrings.bugReport.tr,
                    subtitle: AppStrings.bugReportDescription.tr,
                    onTap: () => Navigator.pushNamed(context, Routes.bugReport),
                  ),
                  _buildSettingsTile(
                    icon: Icons.star_rate,
                    title: AppStrings.rateApp.tr,
                    subtitle: AppStrings.rateAppDescription.tr,
                    onTap: () => Navigator.pushNamed(context, Routes.rateApp),
                  ),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: AppStrings.about.tr,
                    subtitle:
                        '${AppStrings.version.tr} ${_packageInfo?.version ?? '1.0.0'}',
                    onTap: () => Navigator.pushNamed(context, Routes.about),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
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
            child: Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.settings.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderActions(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(bool isDark) {
    return _buildActionButton(
      icon: Icons.add_shopping_cart_outlined,
      onPressed: () {},
      isDark: isDark,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ??
              (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? titleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              )
            : null,
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              size: 20,
            ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getThemeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return AppStrings.themeSystem.tr;
      case ThemeMode.light:
        return AppStrings.themeLight.tr;
      case ThemeMode.dark:
        return AppStrings.themeDark.tr;
    }
  }
}
