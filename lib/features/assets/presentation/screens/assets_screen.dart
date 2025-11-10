import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/core/enums/asset_enums.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/core/utils/number_formatter.dart';
import 'package:asset_it/data/entities/asset_with_values.dart';
import 'package:asset_it/features/assets/presentation/providers/assets_provider.dart';
import 'package:asset_it/features/assets/presentation/widgets/assets_list_item_card.dart';
import 'package:asset_it/features/assets/presentation/screens/assets_welcome_screen.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:provider/provider.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final Map<AssetType, bool> _expandedGroups = {};
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
      _loadAssets();
    });

    for (var type in AssetType.values) {
      _expandedGroups[type] = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);
    final assetsProvider = Provider.of<AssetsProvider>(context, listen: false);

    await financeProvider.loadFinances();
    await assetsProvider.loadAssets();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Map<AssetType, List<AssetWithValues>> _groupAssetsByType(
      List<AssetWithValues> assets) {
    final Map<AssetType, List<AssetWithValues>> grouped = {};

    for (final type in AssetType.values) {
      final typeAssets = assets.where((a) => a.asset.type == type).toList();
      typeAssets.sort((a, b) => a.asset.sortOrder.compareTo(b.asset.sortOrder));
      if (typeAssets.isNotEmpty) {
        grouped[type] = typeAssets;
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: _buildLoadingSkeleton(isDark),
        ),
      );
    }

    return Consumer<AssetsProvider>(
      builder: (context, provider, child) {
        if (provider.assetsWithValues.isEmpty) {
          return const AssetsWelcomeScreen();
        }

        final groupedAssets = _groupAssetsByType(provider.assetsWithValues);
        final orderedTypes = provider.getOrderedAssetTypes(groupedAssets);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
          floatingActionButton: _buildFAB(isDark),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, provider),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAssets,
                    color: Colors.blue.shade400,
                    child: ReorderableListView(
                      padding: const EdgeInsets.all(20),
                      buildDefaultDragHandles: false,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final double elevation = Tween<double>(
                              begin: 0,
                              end: 8,
                            ).evaluate(animation);
                            return Material(
                              elevation: elevation,
                              color: Colors.transparent,
                              shadowColor: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        provider.reorderAssetTypes(oldIndex, newIndex, orderedTypes);
                        HapticFeedback.mediumImpact();
                      },
                      children: [
                        ...orderedTypes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final type = entry.value;
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(type.name),
                            index: index,
                            child: _buildAssetTypeSection(
                              type,
                              groupedAssets[type]!,
                              isDark,
                              provider,
                            ),
                          );
                        }),
                        SizedBox(key: const ValueKey('spacer'), height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssetTypeSection(
      AssetType type, List<AssetWithValues> assets, bool isDark, AssetsProvider provider) {
    final isExpanded = _expandedGroups[type] ?? true;
    final totalValue =
        assets.fold<double>(0, (sum, asset) => sum + asset.currentValue);
    final totalGainLoss = (type != AssetType.loan && type != AssetType.creditCard && type != AssetType.cash)
        ? assets.fold<double>(0, (sum, asset) => sum + asset.gainLoss)
        : 0.0;

    return Container(
      key: ValueKey(type.name),
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedGroups[type] = !isExpanded;
              });
              HapticFeedback.lightImpact();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTypeColor(type).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getTypeIcon(type),
                      color: _getTypeColor(type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${assets.length} ${assets.length == 1 ? AppStrings.item.tr : AppStrings.items.tr}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatGroupValue(type, totalValue),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getGroupValueColor(type, isDark),
                        ),
                      ),
                      if (totalGainLoss != 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: totalGainLoss > 0
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormatter.formatGainLoss(totalGainLoss),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: totalGainLoss > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final totalInitialValue = assets.fold<double>(
                                      0,
                                      (sum, asset) =>
                                          sum + (asset.purchaseValue));
                                  if (totalInitialValue > 0) {
                                    final percentage =
                                        (totalGainLoss / totalInitialValue) *
                                            100;
                                    return Text(
                                      ' (${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: totalGainLoss > 0
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  thickness: 1,
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final double elevation = Tween<double>(
                          begin: 0,
                          end: 6,
                        ).evaluate(animation);
                        final double scale = Tween<double>(
                          begin: 1.0,
                          end: 1.02,
                        ).evaluate(animation);
                        return Transform.scale(
                          scale: scale,
                          child: Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    provider.reorderAssets(type, oldIndex, newIndex, assets);
                    HapticFeedback.lightImpact();
                  },
                  children: assets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final asset = entry.value;
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(asset.asset.id),
                      index: index,
                      child: _buildAssetCard(asset, isDark),
                    );
                  }).toList(),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(AssetType type) {
    switch (type) {
      case AssetType.currency:
        return Icons.attach_money;
      case AssetType.gold:
        return Icons.diamond;
      case AssetType.bankAccount:
        return Icons.account_balance;
      case AssetType.cash:
        return Icons.money;
      case AssetType.creditCard:
        return Icons.credit_card;
      case AssetType.loan:
        return Icons.receipt_long;
      case AssetType.stock:
        return Icons.trending_up;
    }
  }

  Color _getTypeColor(AssetType type) {
    switch (type) {
      case AssetType.currency:
        return AppColors.currencyColor;
      case AssetType.gold:
        return AppColors.goldColor;
      case AssetType.bankAccount:
        return AppColors.bankColor;
      case AssetType.cash:
        return AppColors.cashColor;
      case AssetType.creditCard:
        return AppColors.creditCardColor;
      case AssetType.loan:
        return AppColors.loanColor;
      case AssetType.stock:
        return AppColors.stockColor;
    }
  }

  Widget _buildAssetCard(AssetWithValues assetWithValue, bool isDark) {
    final asset = assetWithValue.asset;
    return AssetsListItemCard(
      assetWithValue: assetWithValue,
      isDark: isDark,
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.asset,
          arguments: asset,
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, AssetsProvider provider) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  Icons.account_balance_wallet_rounded,
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
                      AppStrings.assetsManager.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.manageYourAssets.tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.pushNamed(context, Routes.salaryManager);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.salary.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (provider.assetsWithValues.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildHeaderStats(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderStats(AssetsProvider provider) {
    final totalAssets = provider.assetsList
        .fold<double>(0, (sum, asset) => sum + asset.currentValue);
    final totalLiabilities = provider.liabilitiesList
        .fold<double>(0, (sum, asset) => sum + asset.currentValue.abs());
    final totalGainLoss = provider.assetsWithValues
        .where((asset) => asset.asset.type != AssetType.loan && asset.asset.type != AssetType.creditCard)
        .fold<double>(0, (sum, asset) => sum + asset.gainLoss);

    return Container(
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
        children: [
          Expanded(
            child: _buildStatItem(
              AppStrings.assets.tr,
              NumberFormatter.formatWithSymbol(totalAssets,
                  showDecimals: true),
              Icons.trending_up_rounded,
              '${provider.assetsList.length} ${AppStrings.items.tr}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              AppStrings.liabilities.tr,
              NumberFormatter.formatWithSymbol(totalLiabilities,
                  showDecimals: true),
              Icons.trending_down_rounded,
              '${provider.liabilitiesList.length} ${AppStrings.items.tr}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              AppStrings.gainLoss.tr,
              NumberFormatter.formatGainLoss(totalGainLoss, showDecimals: true),
              totalGainLoss >= 0
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              totalGainLoss >= 0 ? AppStrings.profit.tr : AppStrings.loss.tr,
              valueColor:
                  totalGainLoss >= 0 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, String? subtitle,
      {Color? valueColor}) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton(
      onPressed: () async {
        HapticFeedback.mediumImpact();
        final result = await Navigator.pushNamed(context, Routes.asset);
        if (result == true && mounted) {
          _loadAssets();
        }
      },
      tooltip: AppStrings.addAssetTooltip.tr,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  String _formatGroupValue(AssetType type, double value) {
    if (type == AssetType.creditCard || type == AssetType.loan) {
      final absValue = value.abs();
      return '-${NumberFormatter.formatWithSymbol(absValue)}';
    }

    return NumberFormatter.formatWithSymbol(value.abs());
  }

  Color _getGroupValueColor(AssetType type, bool isDark) {
    return isDark ? Colors.white : Colors.grey.shade800;
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: [
        _buildLoadingHeader(isDark),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildLoadingAssetCard(isDark),
              const SizedBox(height: 12),
              _buildLoadingAssetCard(isDark),
              const SizedBox(height: 12),
              _buildLoadingAssetCard(isDark),
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
          colors: isDark
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [Colors.blue.shade400, Colors.purple.shade400],
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myAssets.tr,
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

  Widget _buildLoadingAssetCard(bool isDark) {
    return Container(
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
        children: [
          Row(
            children: [
              _buildShimmerBox(
                width: 120,
                height: 20,
                borderRadius: 8,
              ),
              const Spacer(),
              _buildShimmerBox(
                width: 80,
                height: 20,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShimmerBox(
            width: double.infinity,
            height: 60,
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          _buildShimmerBox(
            width: double.infinity,
            height: 60,
            borderRadius: 12,
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
