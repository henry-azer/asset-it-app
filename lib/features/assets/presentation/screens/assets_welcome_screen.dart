import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/core/utils/app_strings.dart';

class AssetsWelcomeScreen extends StatefulWidget {
  const AssetsWelcomeScreen({super.key});

  @override
  State<AssetsWelcomeScreen> createState() => _AssetsWelcomeScreenState();
}

class _AssetsWelcomeScreenState extends State<AssetsWelcomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SafeArea(
                top: false,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildWelcomeCard(isDark),
                                const SizedBox(height: 20),
                                _buildAssetTypesInfo(isDark),
                              ],
                            ),
                          ),
                        ),
                        _buildBottomBar(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.welcomeAssetManager.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.startTrackingWealth.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.95),
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400.withOpacity(0.1), Colors.purple.shade400.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: 48,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.trackYourWealth.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.manageAllAssets.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTypesInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.assetCategories.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAssetTypeItem(Icons.attach_money, AppStrings.currency.tr, AppStrings.currencyDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildAssetTypeItem(Icons.diamond, AppStrings.gold.tr, AppStrings.goldDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildAssetTypeItem(Icons.account_balance, AppStrings.bankAccount.tr, AppStrings.bankAccountDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildAssetTypeItem(Icons.money, AppStrings.cash.tr, AppStrings.cashDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildAssetTypeItem(Icons.credit_card, AppStrings.creditCard.tr, AppStrings.creditCardDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildAssetTypeItem(Icons.receipt_long, AppStrings.loan.tr, AppStrings.loanDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildAssetTypeItem(Icons.trending_up, AppStrings.stock.tr, AppStrings.stockDesc.tr, isDark),
        ],
      ),
    );
  }

  Widget _buildAssetTypeItem(IconData icon, String title, String description, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400.withOpacity(0.15), Colors.purple.shade400.withOpacity(0.15)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
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
          child: ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final result = await Navigator.pushNamed(context, Routes.asset);
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              AppStrings.createFirstAsset.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
