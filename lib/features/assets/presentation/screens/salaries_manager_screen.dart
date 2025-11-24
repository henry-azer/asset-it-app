import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/core/utils/number_formatter.dart';
import 'package:asset_it/data/entities/salary.dart';
import 'package:asset_it/features/assets/presentation/providers/salary_provider.dart';
import 'package:provider/provider.dart';

class SalariesManagerScreen extends StatefulWidget {
  const SalariesManagerScreen({super.key});

  @override
  State<SalariesManagerScreen> createState() => _SalariesManagerScreenState();
}

class _SalariesManagerScreenState extends State<SalariesManagerScreen> {
  bool _isInitialLoading = true;
  final Map<String, bool> _expandedSalaries = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalaries();
    });
  }

  Future<void> _loadSalaries() async {
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    await salaryProvider.loadSalaries();

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
        backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: _buildLoadingSkeleton(isDark),
        ),
      );
    }

    return Consumer<SalaryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
          floatingActionButton: _buildFAB(isDark),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, provider),
                Expanded(
                  child: provider.salaries.isEmpty
                      ? _buildEmptyContent(isDark)
                      : RefreshIndicator(
                          onRefresh: _loadSalaries,
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
                              if (oldIndex < provider.salaries.length &&
                                  newIndex <= provider.salaries.length) {
                                final provider = Provider.of<SalaryProvider>(context, listen: false);
                                provider.reorderSalaries(oldIndex, newIndex);
                                HapticFeedback.mediumImpact();
                              }
                            },
                            children: [
                              ...provider.salaries.asMap().entries.map((entry) {
                                final index = entry.key;
                                final salary = entry.value;
                                return ReorderableDragStartListener(
                                  key: ValueKey(salary.id),
                                  index: index,
                                  child: _buildSalaryCard(salary, isDark),
                                );
                              }),
                              IgnorePointer(
                                key: const ValueKey('spacer'),
                                child: const SizedBox(height: 80),
                              ),
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

  Widget _buildHeader(bool isDark, SalaryProvider provider) {
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
                      AppStrings.salaryManager.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.manageSalaries.tr,
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
          _buildHeaderStats(provider),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(SalaryProvider provider) {
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
              AppStrings.salaries.tr,
              NumberFormatter.formatWithSymbol(provider.totalSalaries, showDecimals: true),
              Icons.attach_money_rounded,
              '${provider.salaries.length} ${AppStrings.items.tr}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              AppStrings.totalSpendings.tr,
              NumberFormatter.formatWithSymbol(provider.totalSpendings, showDecimals: true),
              Icons.shopping_cart_rounded,
              '',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              AppStrings.remainingAmount.tr,
              NumberFormatter.formatWithSymbol(provider.totalRemaining, showDecimals: true),
              Icons.savings_rounded,
              '',
              valueColor: provider.totalRemaining >= 0 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, String? subtitle, {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
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
        if (subtitle != null && subtitle.isNotEmpty) ...[
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

  Widget _buildSalaryCard(Salary salary, bool isDark) {
    final isExpanded = _expandedSalaries[salary.id] ?? true;

    return Container(
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
            onTap: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.pushNamed(
                context,
                Routes.salary,
                arguments: salary,
              );
              if (result == true && mounted) {
                _loadSalaries();
              }
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
                      color: Colors.blue.shade400.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade400.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue.shade400,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.salary.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${salary.spendings.length} ${salary.spendings.length == 1 ? AppStrings.item.tr : AppStrings.items.tr}',
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
                        NumberFormatter.formatWithSymbol(salary.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      // if (salary.totalSpendings > 0) ...[

                      // ],
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: salary.remainingAmount >= 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          NumberFormatter.formatWithSymbol(salary.remainingAmount),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: salary.remainingAmount >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          NumberFormatter.formatWithSymbol(salary.totalSpendings),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (salary.totalSpendings > 0) ...[

              const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedSalaries[salary.id] = !isExpanded;
                      });
                      HapticFeedback.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.expand_more,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
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
                ...salary.spendings.map((spending) {
                  final percentage = salary.amount > 0
                      ? (spending.amount / salary.amount) * 100
                      : 0.0;
                  return _buildSpendingItem(spending, percentage, isDark, salary);
                }),
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

  Widget _buildSpendingItem(dynamic spending, double percentage, bool isDark, Salary salary) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final result = await Navigator.pushNamed(
          context,
          Routes.salary,
          arguments: salary,
        );
        if (result == true && mounted) {
          _loadSalaries();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spending.type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormatter.formatWithSymbol(spending.amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '(${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFAB(bool isDark) {
    return FloatingActionButton(
      onPressed: () async {
        HapticFeedback.mediumImpact();
        final result = await Navigator.pushNamed(context, Routes.salary);
        if (result == true && mounted) {
          _loadSalaries();
        }
      },
      tooltip: AppStrings.addSalaryTooltip.tr,
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

  Widget _buildEmptyContent(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.welcomeSalaryManager.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.startTrackingSalary.tr,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: [
        _buildLoadingHeader(isDark),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildLoadingCard(isDark),
              const SizedBox(height: 12),
              _buildLoadingCard(isDark),
              const SizedBox(height: 12),
              _buildLoadingCard(isDark),
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
                      AppStrings.salaryManager.tr,
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

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
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
