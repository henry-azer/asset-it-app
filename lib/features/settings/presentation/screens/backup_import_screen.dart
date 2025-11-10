import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/settings/data/providers/local_backup_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/assets/presentation/providers/assets_provider.dart';
import 'package:provider/provider.dart';

class BackupImportScreen extends StatefulWidget {
  const BackupImportScreen({super.key});

  @override
  State<BackupImportScreen> createState() => _BackupImportScreenState();
}

class _BackupImportScreenState extends State<BackupImportScreen> {
  late LocalBackupProvider _backupProvider;
  bool _isValidating = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _backupProvider = LocalBackupProvider();
  }

  @override
  void dispose() {
    _backupProvider.dispose();
    super.dispose();
  }

  Future<void> _validateFile() async {
    if (_isValidating || _isImporting || _backupProvider.isProcessing) return;

    setState(() => _isValidating = true);

    try {
      final result = await _backupProvider.validateBackupFile();

      if (mounted) {
        setState(() => _isValidating = false);

        if (result.success && result.backupInfo != null) {
          _showValidationDialog(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? AppStrings.invalidBackupFile.tr),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isValidating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.validationFailed.tr}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    if (_isImporting || _backupProvider.isProcessing) return;

    final assetsProvider = Provider.of<AssetsProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    
    final hasExistingData = assetsProvider.assets.isNotEmpty || financeProvider.finances.isNotEmpty;
    
    if (hasExistingData) {
      final confirmed = await _showRestoreConfirmation();
      if (confirmed != true) {
        return;
      }
    }

    setState(() => _isImporting = true);

    try {
      final result = await _backupProvider.importAndRestore();

      if (mounted) {
        if (result.success) {
          await _reloadAllProviders();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppStrings.databaseRestoredSuccessfully.tr}'),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? AppStrings.importFailed.tr),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.importFailed.tr}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _reloadAllProviders() async {
    try {
      final currencyChoiceProvider = Provider.of<CurrencyChoiceProvider>(context, listen: false);
      final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
      final assetsProvider = Provider.of<AssetsProvider>(context, listen: false);

      await currencyChoiceProvider.loadCurrencyChoices();
      
      if (currencyChoiceProvider.hasCurrencyChoices) {
        await financeProvider.loadFinances();
        await assetsProvider.loadAssets();
      }
    } catch (e) {
      print('Error reloading providers: $e');
    }
  }

  Future<bool?> _showRestoreConfirmation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.red.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.restoreWarning.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.restoreWarningMessage.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1329)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.cancel.tr,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.red.shade400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.restore.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                padding: const EdgeInsets.all(20),
                children: [
                  _buildImportOptions(isDark),
                  const SizedBox(height: 80),
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
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                      AppStrings.importData.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.importDataSubtitle.tr,
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
        ],
      ),
    );
  }

  Widget _buildImportOptions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImportOption(
          isDark: isDark,
          icon: Icons.restore_rounded,
          title: AppStrings.importFromFile.tr,
          description: AppStrings.importFileDescription.tr,
          color: Colors.green.shade600,
          onTap: _importBackup,
          isLoading: _isImporting,
        ),
        _buildImportOption(
          isDark: isDark,
          icon: Icons.search_rounded,
          title: AppStrings.validateFile.tr,
          description: AppStrings.validateFileDesc.tr,
          color: Colors.blue.shade600,
          onTap: _validateFile,
          isLoading: _isValidating,
        ),
      ],
    );
  }

  Widget _buildImportOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading || _isImporting || _isValidating || _backupProvider.isProcessing ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
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
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showValidationDialog(ImportResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backupInfo = result.backupInfo!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.validBackupFile.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(isDark ? 0.1 : 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(AppStrings.backupAppName.tr, backupInfo.appName, isDark),
                    const SizedBox(height: 12),
                    _buildInfoRow(AppStrings.backupVersion.tr, backupInfo.version, isDark),
                    const SizedBox(height: 12),
                    _buildInfoRow(AppStrings.backupDate.tr, backupInfo.formattedExportDate, isDark),
                    const SizedBox(height: 12),
                    _buildInfoRow(AppStrings.totalItems.tr, '${backupInfo.assetCount + backupInfo.financeCount + backupInfo.currencyChoiceCount + backupInfo.baseCurrencyCount + backupInfo.userCount}', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.close.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
