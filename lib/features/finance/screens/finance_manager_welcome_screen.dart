import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/core/services/currency_service.dart';
import 'package:asset_it/injection_container.dart';
import 'package:asset_it/core/utils/app_colors.dart';

class FinanceManagerWelcomeScreen extends StatefulWidget {
  const FinanceManagerWelcomeScreen({super.key});

  @override
  State<FinanceManagerWelcomeScreen> createState() =>
      _FinanceManagerWelcomeScreenState();
}

class _FinanceManagerWelcomeScreenState extends State<FinanceManagerWelcomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CurrencyService _currencyService = sl<CurrencyService>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedCurrency;
  bool _isLoading = false;
  bool _isLoadingCurrencies = false;
  bool _failedToFetchCurrencies = false;
  bool _isCustomMode = false;
  List<String> _availableCurrencies = [''];
  final _customCodeFieldKey = GlobalKey<FormFieldState>();
  final _customNameFieldKey = GlobalKey<FormFieldState>();
  final _customSymbolFieldKey = GlobalKey<FormFieldState>();
  final TextEditingController _currencySearchController =
      TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _currencyNameController = TextEditingController();
  final TextEditingController _currencySymbolController =
      TextEditingController();
  final FocusNode _currencyFocusNode = FocusNode();

  bool _keyboardVisible = false;

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isVisible = bottomInset > 0;

    if (isVisible != _keyboardVisible) {
      setState(() {
        _keyboardVisible = isVisible;
      });
    }
  }

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

    _currencyFocusNode.addListener(() {
      if (!_currencyFocusNode.hasFocus && mounted) {
        if (_currencySearchController.text.isEmpty) {
          setState(() {
            _selectedCurrency = null;
            _clearCurrencyFields();
          });
        }
      }
    });

    _fetchAvailableCurrencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _currencySearchController.dispose();
    _currencyCodeController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    _currencyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _currencyFocusNode.hasFocus) {
      _currencyFocusNode.unfocus();
    }
  }

  void _clearFocusAndSelection() {
    _currencyFocusNode.unfocus();
    setState(() {
      _currencySearchController.clear();
      _selectedCurrency = null;
      _clearCurrencyFields();
    });
  }

  void _updateCurrencyFields(String code) {
    _currencyCodeController.text = code;
    _currencyNameController.text = CurrencyService.getCurrencyName(code);
    _currencySymbolController.text = CurrencyService.getCurrencySymbol(code);
  }

  void _clearCurrencyFields() {
    _currencyCodeController.clear();
    _currencyNameController.clear();
    _currencySymbolController.clear();
  }

  Future<void> _fetchAvailableCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    final currencies = await _currencyService.fetchAndCacheCurrencies();

    if (mounted) {
      setState(() {
        _availableCurrencies = currencies;
        _failedToFetchCurrencies = currencies.length == 1;
        _isLoadingCurrencies = false;
      });
    }
  }

  void _enableCustomMode() {
    setState(() {
      _isCustomMode = true;
      _selectedCurrency = null;
      _currencySearchController.clear();
      _clearCurrencyFields();
    });
  }

  void _disableCustomMode() {
    setState(() {
      _isCustomMode = false;
      _selectedCurrency = null;
      _currencySearchController.clear();
      _clearCurrencyFields();
    });
  }

  Future<void> _confirmCurrency() async {
    if (_isLoading || _selectedCurrency == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currencyChoiceProvider = context.read<CurrencyChoiceProvider>();
      final financeProvider = context.read<FinanceProvider>();

      final currencyCode = _currencyCodeController.text.trim().toUpperCase();
      final currencyName = _currencyNameController.text.trim();
      final currencySymbol = _currencySymbolController.text.trim();

      if (_isCustomMode) {
        await _currencyService.addCustomCurrency(
          code: currencyCode,
          name: currencyName,
          symbol: currencySymbol,
        );
      }

      await currencyChoiceProvider.createCurrencyChoice(
          baseCurrency: currencyCode,
          currencyName: currencyName,
          currencySymbol: currencySymbol,
          setAsActive: true);

      if (mounted) {
        await financeProvider.loadFinances();

        await Future.delayed(const Duration(milliseconds: 800));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorPrefix.tr}: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (_currencyFocusNode.hasFocus) {
          _currencyFocusNode.unfocus();
          if (_currencySearchController.text.isEmpty) {
            setState(() {
              _selectedCurrency = null;
              _clearCurrencyFields();
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
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
                                  if (!_failedToFetchCurrencies)
                                    _buildFinanceInfoCard(isDark),
                                  if (!_failedToFetchCurrencies)
                                    const SizedBox(height: 20),
                                  if (!_isCustomMode) ...[
                                    _buildCurrencySelector(isDark),
                                    const SizedBox(height: 16),
                                    _buildCustomCurrencyButton(isDark),
                                  ],
                                  if (_isCustomMode) ...[
                                    _buildCustomCurrencyFields(isDark),
                                    const SizedBox(height: 16),
                                    _buildBackToSelectorButton(isDark),
                                  ],
                                  if (_selectedCurrency != null &&
                                      !_isCustomMode) ...[
                                    const SizedBox(height: 16),
                                    _buildCurrencyInfoCard(isDark),
                                  ],
                                  if (_failedToFetchCurrencies) ...[
                                    const SizedBox(height: 16),
                                    _buildWarningCard(isDark),
                                  ],
                                  const SizedBox(height: 20),
                                  if (_keyboardVisible) _buildBottomBar(isDark),
                                ],
                              ),
                            ),
                          ),
                          if (!_keyboardVisible) _buildBottomBar(isDark),
                        ],
                      ),
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
            AppStrings.welcomeFinanceManager.tr,
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
              AppStrings.setupBaseCurrency.tr,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400.withOpacity(0.1),
                  Colors.purple.shade400.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.currency_exchange_rounded,
              size: 48,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.yourFinancialFoundation.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.chooseBaseCurrencyDesc.tr,
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

  Widget _buildFinanceInfoCard(bool isDark) {
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
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.whatYouCanTrack.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFinanceInfoItem(
              Icons.attach_money,
              AppStrings.trackCurrencies.tr,
              AppStrings.trackCurrenciesDesc.tr,
              isDark),
          const SizedBox(height: 12),
          _buildFinanceInfoItem(Icons.diamond, AppStrings.goldPrices.tr,
              AppStrings.goldPricesDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildFinanceInfoItem(Icons.trending_up, AppStrings.stockValues.tr,
              AppStrings.stockValuesDesc.tr, isDark),
          const SizedBox(height: 12),
          _buildFinanceInfoItem(
              Icons.analytics_rounded,
              AppStrings.portfolioOverviewLabel.tr,
              AppStrings.portfolioOverviewDesc.tr,
              isDark),
        ],
      ),
    );
  }

  Widget _buildFinanceInfoItem(
      IconData icon, String title, String description, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400.withOpacity(0.15),
                Colors.purple.shade400.withOpacity(0.15)
              ],
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

  Widget _buildCurrencySelector(bool isDark) {
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
                    colors: [
                      Colors.blue.shade400.withOpacity(0.1),
                      Colors.purple.shade400.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_money_rounded,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.selectCurrencyLabel.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RawAutocomplete<String>(
            textEditingController: _currencySearchController,
            focusNode: _currencyFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _availableCurrencies;
              }
              return _availableCurrencies.where((currency) {
                final searchLower = textEditingValue.text.toLowerCase();
                final name =
                    CurrencyService.getCurrencyName(currency).toLowerCase();
                return currency.toLowerCase().contains(searchLower) ||
                    name.contains(searchLower);
              });
            },
            onSelected: (String selection) {
              setState(() {
                _selectedCurrency = selection;
                _currencySearchController.text = selection;
                _updateCurrencyFields(selection);
              });
              HapticFeedback.lightImpact();
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: AppStrings.currencyLabel.tr,
                  hintText: _isLoadingCurrencies
                      ? AppStrings.loadingCurrencies.tr
                      : AppStrings.searchCurrencies.tr,
                  prefixIcon: _isLoadingCurrencies
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.currency_exchange_rounded,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: _clearFocusAndSelection,
                        )
                      : null,
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF0F1329) : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                enabled: !_isLoadingCurrencies,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.77,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.25,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final currency = options.elementAt(index);
                        final name = CurrencyService.getCurrencyName(currency);
                        final symbol =
                            CurrencyService.getCurrencySymbol(currency);

                        return InkWell(
                          onTap: () => onSelected(currency),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400.withOpacity(0.1),
                                        Colors.purple.shade400.withOpacity(0.1)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      symbol,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currency,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                      .lightTextSecondary,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInfoCard(bool isDark) {
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
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
                _currencySymbolController.text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currencyCodeController.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyNameController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.selected.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.unableToFetchCurrencies.tr,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: _selectedCurrency != null
                  ? BoxDecoration(
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
                    )
                  : null,
              child: ElevatedButton(
                onPressed: _selectedCurrency != null && !_isLoading
                    ? _confirmCurrency
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCurrency != null
                      ? Colors.transparent
                      : (isDark
                          ? const Color(0xFF1A1F3A)
                          : Colors.grey.shade200),
                  foregroundColor: _selectedCurrency != null
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        AppStrings.confirmCurrency.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.changeThisLater.tr,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCurrencyButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextButton.icon(
        onPressed: _enableCustomMode,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          Icons.add_circle_outline_rounded,
          color: Colors.blue.shade600,
          size: 22,
        ),
        label: Text(
          AppStrings.addCustomCurrency.tr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade800,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBackToSelectorButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextButton.icon(
        onPressed: _disableCustomMode,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: Colors.blue.shade600,
          size: 22,
        ),
        label: Text(
          AppStrings.chooseFromCurrencies.tr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade800,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCurrencyFields(bool isDark) {
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
                    colors: [
                      Colors.blue.shade400.withOpacity(0.1),
                      Colors.purple.shade400.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.customCurrency.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCustomTextField(
            fieldKey: _customCodeFieldKey,
            controller: _currencyCodeController,
            label: AppStrings.currencyCode.tr,
            hint: AppStrings.currencyCodeHint.tr,
            icon: Icons.code_rounded,
            isDark: isDark,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.enterCurrencyCode.tr;
              }
              if (value.trim().length < 2) {
                return AppStrings.codeMinLength.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildCustomTextField(
            fieldKey: _customNameFieldKey,
            controller: _currencyNameController,
            label: AppStrings.currencyName.tr,
            hint: AppStrings.currencyNameHint.tr,
            icon: Icons.label_outline_rounded,
            isDark: isDark,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.enterCurrencyName.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildCustomTextField(
            fieldKey: _customSymbolFieldKey,
            controller: _currencySymbolController,
            label: AppStrings.currencySymbol.tr,
            hint: AppStrings.currencySymbolHint.tr,
            icon: Icons.currency_exchange_rounded,
            isDark: isDark,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.enterCurrencySymbol.tr;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required GlobalKey<FormFieldState> fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.grey.shade800,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: Colors.blue.shade600,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F1329) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade600,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
      validator: validator,
      onChanged: (value) {
        fieldKey.currentState?.validate();

        setState(() {
          final isCodeValid =
              _customCodeFieldKey.currentState?.isValid ?? false;
          final isNameValid =
              _customNameFieldKey.currentState?.isValid ?? false;
          final isSymbolValid =
              _customSymbolFieldKey.currentState?.isValid ?? false;

          _selectedCurrency =
              (isCodeValid && isNameValid && isSymbolValid) ? 'CUSTOM' : null;
        });
      },
    );
  }
}
