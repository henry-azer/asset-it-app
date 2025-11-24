import 'package:asset_it/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/features/finance/screens/finance_manager_welcome_screen.dart';
import 'package:asset_it/core/services/currency_service.dart';
import 'package:asset_it/data/entities/finance.dart';
import 'package:asset_it/core/enums/finance_enums.dart';

class FinanceManagerScreen extends StatefulWidget {
  const FinanceManagerScreen({super.key});

  @override
  State<FinanceManagerScreen> createState() => _FinanceManagerScreenState();
}

class _FinanceManagerScreenState extends State<FinanceManagerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final TextEditingController _currencySearchController =
      TextEditingController();
  final TextEditingController _goldSearchController = TextEditingController();
  final TextEditingController _stockSearchController = TextEditingController();
  String _currencySearchQuery = '';
  String _goldSearchQuery = '';
  String _stockSearchQuery = '';
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();

    _currencySearchController.addListener(() {
      setState(() {
        _currencySearchQuery = _currencySearchController.text.toLowerCase();
      });
    });
    _goldSearchController.addListener(() {
      setState(() {
        _goldSearchQuery = _goldSearchController.text.toLowerCase();
      });
    });
    _stockSearchController.addListener(() {
      setState(() {
        _stockSearchQuery = _stockSearchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinances();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _currencySearchController.dispose();
    _goldSearchController.dispose();
    _stockSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadFinances() async {
    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);

    await financeProvider.loadFinances();

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
        body: SafeArea(
          child: _buildLoadingSkeleton(isDark),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Consumer2<CurrencyChoiceProvider, FinanceProvider>(
          builder: (context, currencyChoiceProvider, financeProvider, child) {
            if (!currencyChoiceProvider.hasCurrencyChoices) {
              return const FinanceManagerWelcomeScreen();
            }

            return Column(
              children: [
                _buildHeader(isDark, currencyChoiceProvider, financeProvider),
                _buildTabBar(isDark, financeProvider),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCurrenciesTab(financeProvider, isDark),
                      _buildGoldTab(financeProvider, isDark),
                      _buildStocksTab(financeProvider, isDark),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer2<CurrencyChoiceProvider, FinanceProvider>(
        builder: (context, currencyChoiceProvider, financeProvider, child) {
          if (!currencyChoiceProvider.hasCurrencyChoices) {
            return const SizedBox.shrink();
          }

          return _buildFloatingActionButton(isDark);
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, CurrencyChoiceProvider currencyProvider,
      FinanceProvider financeProvider) {
    final baseCurrency = currencyProvider.getActiveCurrencyCode();
    final currencySymbol = currencyProvider.getActiveCurrencySymbol();

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
                  Icons.account_balance_rounded,
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
                      AppStrings.financeManager.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.manageYourFinances.tr,
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
                  await Navigator.pushNamed(context, Routes.currencyManager);
                  if (mounted) {
                    _loadFinances();
                  }
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
                        Icons.currency_exchange_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        baseCurrency,
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
          const SizedBox(height: 16),
          Flexible(
            child: _buildHeaderStats(financeProvider, currencySymbol, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(
      FinanceProvider provider, String symbol, bool isDark) {
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
              AppStrings.currency.tr,
              provider.currencyFinances.length.toString(),
              Icons.currency_exchange_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              AppStrings.gold.tr,
              provider.goldFinances.length.toString(),
              Icons.diamond_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              AppStrings.stocks.tr,
              provider.stockFinances.length.toString(),
              Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    IconData icon;
    String tooltip;
    FinanceType type;

    switch (_tabController.index) {
      case 0:
        icon = Icons.currency_exchange_rounded;
        tooltip = AppStrings.addCurrency.tr;
        type = FinanceType.currency;
        break;
      case 1:
        icon = Icons.diamond_rounded;
        tooltip = AppStrings.addGold.tr;
        type = FinanceType.gold;
        break;
      case 2:
        icon = Icons.trending_up_rounded;
        tooltip = AppStrings.addStock.tr;
        type = FinanceType.stock;
        break;
      default:
        icon = Icons.add_rounded;
        tooltip = AppStrings.add.tr;
        type = FinanceType.currency;
    }

    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _navigateToAddFinanceScreen(type);
      },
      tooltip: tooltip,
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
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark, FinanceProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      padding: const EdgeInsets.all(6),
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
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade500, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.currency_exchange_rounded, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    AppStrings.currencies.tr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond_rounded, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppStrings.gold.tr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up_rounded, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppStrings.stocks.tr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Finance> _filterFinances(List<Finance> finances, String query) {
    if (query.isEmpty) return finances;
    return finances.where((finance) {
      final code = finance.code.toLowerCase();
      final name = (finance.name ?? '').toLowerCase();
      return code.contains(query) || name.contains(query);
    }).toList();
  }

  void _navigateToAddFinanceScreen(FinanceType type) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.finance,
      arguments: {'type': type},
    );
    if (result == true && mounted) {
      _loadFinances();
    }
  }

  void _navigateToEditFinance(Finance finance) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.pushNamed(
      context,
      Routes.finance,
      arguments: {
        'type': finance.type,
        'finance': finance,
      },
    );
    if (result == true && mounted) {
      _loadFinances();
    }
  }

  Widget _buildCurrenciesTab(FinanceProvider provider, bool isDark) {
    final filteredCurrencies =
        _filterFinances(provider.currencyFinances, _currencySearchQuery);

    if (provider.currencyFinances.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.loadFinances();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(
              isDark: isDark,
              icon: Icons.currency_exchange_rounded,
              title: AppStrings.noCurrenciesYet.tr,
              description: AppStrings.addCurrenciesToTrack.tr,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildSearchBar(
            controller: _currencySearchController,
            hint: AppStrings.searchCurrenciesHint.tr,
            isDark: isDark,
          ),
          Expanded(
            child: filteredCurrencies.isEmpty
                ? _buildNoResultsFound(isDark)
                : RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadFinances();
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        ...filteredCurrencies.map((finance) {
                          return _buildFinanceCard(
                            finance: finance,
                            provider: provider,
                            isDark: isDark,
                          );
                        }).toList(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldTab(FinanceProvider provider, bool isDark) {
    final filteredGold =
        _filterFinances(provider.goldFinances, _goldSearchQuery);

    if (provider.goldFinances.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.loadFinances();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(
              isDark: isDark,
              icon: Icons.diamond_rounded,
              title: AppStrings.noGoldItems.tr,
              description: AppStrings.addGoldToTrack.tr,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildSearchBar(
            controller: _goldSearchController,
            hint: AppStrings.searchGoldHint.tr,
            isDark: isDark,
          ),
          Expanded(
            child: filteredGold.isEmpty
                ? _buildNoResultsFound(isDark)
                : RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadFinances();
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        ...filteredGold.map((finance) {
                          return _buildFinanceCard(
                            finance: finance,
                            provider: provider,
                            isDark: isDark,
                          );
                        }).toList(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksTab(FinanceProvider provider, bool isDark) {
    final filteredStocks =
        _filterFinances(provider.stockFinances, _stockSearchQuery);

    if (provider.stockFinances.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.loadFinances();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(
              isDark: isDark,
              icon: Icons.trending_up_rounded,
              title: AppStrings.noStockItems.tr,
              description: AppStrings.addStocksToTrack.tr,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildSearchBar(
            controller: _stockSearchController,
            hint: AppStrings.searchStocksHint.tr,
            isDark: isDark,
          ),
          Expanded(
            child: filteredStocks.isEmpty
                ? _buildNoResultsFound(isDark)
                : RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadFinances();
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        ...filteredStocks.map((finance) {
                          return _buildFinanceCard(
                            finance: finance,
                            provider: provider,
                            isDark: isDark,
                          );
                        }).toList(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    controller.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.blue.shade400,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noResultsFound.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tryDifferentSearchTerm.tr,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.purple.shade300],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard({
    required Finance finance,
    required FinanceProvider provider,
    required bool isDark,
  }) {
    final symbol = finance.type == FinanceType.currency
        ? CurrencyService.getCurrencySymbol(finance.code).substring(0, 
            CurrencyService.getCurrencySymbol(finance.code).length > 3 ? 3 : CurrencyService.getCurrencySymbol(finance.code).length)
        : finance.code
            .substring(0, finance.code.length > 2 ? 2 : finance.code.length);
    final isCurrency = finance.type == FinanceType.currency;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finance.code,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (finance.name != null && finance.name!.isNotEmpty)
                  Text(
                    finance.name!,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F1329), const Color(0xFF1A1F3A)]
                    : [Colors.grey.shade50, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrency
                      ? Icons.currency_exchange_rounded
                      : finance.type == FinanceType.gold
                          ? Icons.diamond_rounded
                          : Icons.trending_up_rounded,
                  size: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  finance.value.toStringAsFixed(4),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToEditFinance(finance);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F1329), const Color(0xFF1A1F3A)]
                      : [Colors.grey.shade50, Colors.grey.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.edit_rounded,
                color: isDark ? Colors.white60 : Colors.grey.shade700,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: [
        _buildLoadingHeader(isDark),
        const SizedBox(height: 12),
        _buildLoadingTabBar(isDark),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
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
                      AppStrings.financeManager.tr,
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

  Widget _buildLoadingTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(6),
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
      child: Row(
        children: [
          Expanded(
            child: _buildShimmerBox(
              width: double.infinity,
              height: 40,
              borderRadius: 12,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildShimmerBox(
              width: double.infinity,
              height: 40,
              borderRadius: 12,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildShimmerBox(
              width: double.infinity,
              height: 40,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
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
      ),
      child: Row(
        children: [
          _buildShimmerBox(
            width: 52,
            height: 52,
            borderRadius: 14,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(
                  width: 100,
                  height: 16,
                  borderRadius: 8,
                ),
                const SizedBox(height: 6),
                _buildShimmerBox(
                  width: 150,
                  height: 12,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
          _buildShimmerBox(
            width: 80,
            height: 40,
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
