import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/core/utils/number_formatter.dart';
import 'package:asset_it/features/assets/presentation/providers/assets_provider.dart';
import 'package:asset_it/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:asset_it/features/dashboard/presentation/widgets/dashboard_distribution_chart.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late AnimationController _animationController;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetsProvider>(context, listen: false);
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);

    if (!financeProvider.isFinancesLoaded) {
      await financeProvider.loadFinances();
    }
    
    await assetProvider.loadAssets();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    dashboardProvider.updateAssets(assetProvider.assetsWithValues);

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
        body: _buildLoadingSkeleton(isDark),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: Consumer2<AssetsProvider, DashboardProvider>(
        builder: (context, assetProvider, dashboardProvider, child) {
          if (assetProvider.assetsWithValues.isNotEmpty &&
              dashboardProvider.assetsWithValues.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              dashboardProvider.updateAssets(assetProvider.assetsWithValues);
            });
          }

          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: _buildHeader(isDark, dashboardProvider),
              ),
              Expanded(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _loadData,
                    color: Colors.blue.shade400,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildStatCards(dashboardProvider, isDark),
                        if (dashboardProvider
                            .assetDistribution.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDistributionCard(
                              dashboardProvider, isDark),
                        ],
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }

  Widget _buildHeader(bool isDark, DashboardProvider provider) {
    final isPositive = provider.netWorth >= 0;
    final hasData = !_isInitialLoading && provider.assetsWithValues.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
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
                      AppStrings.dashboard.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.portfolioOverview.tr,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.netWorth.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            if (hasData && !isPositive)
                              const Text(
                                '- ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            Text(
                              hasData
                                  ? NumberFormatter.formatCurrency(
                                      provider.netWorth.abs())
                                  : '---',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardProvider provider, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: AppStrings.totalAssets.tr,
                value:
                    NumberFormatter.formatCurrency(provider.totalAssetsValue),
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green,
                isDark: isDark,
                subtitle: '${provider.totalAssetCount} ${AppStrings.items.tr}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: AppStrings.liabilities.tr,
                value: NumberFormatter.formatCurrency(
                    provider.totalLiabilitiesValue),
                icon: Icons.credit_card_rounded,
                color: Colors.orange,
                isDark: isDark,
                subtitle: '${provider.totalLiabilityCount} ${AppStrings.items.tr}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: AppStrings.totalGainLoss.tr,
                value: NumberFormatter.formatCurrency(
                    provider.totalGainLoss.abs()),
                icon: provider.totalGainLoss >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: provider.totalGainLoss >= 0 ? Colors.blue : Colors.red,
                isDark: isDark,
                percentage: provider.totalGainLossPercentage,
                isPositive: provider.totalGainLoss >= 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: AppStrings.assetCount.tr,
                value: provider.assetCount.values
                    .fold(0, (sum, count) => sum + count)
                    .toString(),
                icon: Icons.dashboard_rounded,
                color: Colors.purple,
                isDark: isDark,
                subtitle: '${provider.assetDistribution.length} ${AppStrings.types.tr}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    String? subtitle,
    double? percentage,
    bool? isPositive,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.18,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (percentage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPositive!
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isPositive ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributionCard(DashboardProvider provider, bool isDark) {
    return DashboardDistributionChart(
      distribution: provider.assetDistribution,
      totalAssetsValue: provider.totalAssetsValue,
      isDark: isDark,
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: _buildLoadingHeader(isDark),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildLoadingStatCards(isDark),
              SizedBox(height: 16),
              _buildLoadingDistributionCard(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHeader(bool isDark) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
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
                      AppStrings.dashboard.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.loading.tr,
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
          const Spacer(),
          _buildShimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCards(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLoadingStatCard(isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLoadingStatCard(isDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLoadingStatCard(isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLoadingStatCard(isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingStatCard(bool isDark) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.21,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(
                width: 48,
                height: 48,
                borderRadius: 12,
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          _buildShimmerBox(
            width: 100,
            height: 16,
            borderRadius: 8,
          ),
          const SizedBox(height: 8),
          _buildShimmerBox(
            width: 140,
            height: 24,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDistributionCard(bool isDark) {
    return Container(
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildShimmerBox(
                width: 150,
                height: 20,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildShimmerBox(
            width: 200,
            height: 200,
            borderRadius: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
