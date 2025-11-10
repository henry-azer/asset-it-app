import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/services/currency_service.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/injection_container.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> with WidgetsBindingObserver {
  final CurrencyService _currencyService = sl<CurrencyService>();
  final _formKey = GlobalKey<FormState>();
  final _customCodeFieldKey = GlobalKey<FormFieldState>();
  final _customNameFieldKey = GlobalKey<FormFieldState>();
  final _customSymbolFieldKey = GlobalKey<FormFieldState>();
  final _currencyCodeController = TextEditingController();
  final _currencyNameController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _currencySearchController = TextEditingController();
  final _currencyFocusNode = FocusNode();
  
  List<String> _availableCurrencies = [];
  String? _selectedCurrency;
  bool _isLoadingCurrencies = false;
  bool _isLoading = false;
  bool _failedToFetchCurrencies = false;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableCurrencies();
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currencyCodeController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    _currencySearchController.dispose();
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
  
  Future<void> _fetchAvailableCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });
    
    final currencies = await _currencyService.fetchAndCacheCurrencies();
    
    setState(() {
      _availableCurrencies = currencies;
      _failedToFetchCurrencies = currencies.length == 1;
      _isLoadingCurrencies = false;
    });
  }

  void _updateCurrencyFields(String code) {
    _currencyCodeController.text = code;
    _currencyNameController.text = CurrencyService.getCurrencyName(code);
    _currencySymbolController.text = CurrencyService.getCurrencySymbol(code);
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

  void _clearCurrencyFields() {
    _currencyCodeController.clear();
    _currencyNameController.clear();
    _currencySymbolController.clear();
  }

  Future<void> _createCurrencyChoice() async {
    if (_selectedCurrency == null || _isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final currencyChoiceProvider = Provider.of<CurrencyChoiceProvider>(context, listen: false);
    
    final currencyCode = _currencyCodeController.text.trim().toUpperCase();
    final currencyName = _currencyNameController.text.trim();
    final currencySymbol = _currencySymbolController.text.trim();
    
    final existingChoices = currencyChoiceProvider.currencyChoices;
    final alreadyExists = existingChoices.any((choice) => choice.baseCurrency == currencyCode);
    
    if (alreadyExists && mounted) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.currencyAlreadyExistsError.tr.replaceAll('{code}', currencyCode)),
        ),
      );
      return;
    }
    
    if (_isCustomMode) {
      await _currencyService.addCustomCurrency(
        code: currencyCode,
        name: currencyName,
        symbol: currencySymbol,
      );
    }
    
    final choice = await currencyChoiceProvider.createCurrencyChoice(
      baseCurrency: currencyCode,
      currencyName: currencyName,
      currencySymbol: currencySymbol,
      setAsActive: true,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (choice != null) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.failedToCreateCurrency.tr.replaceAll('{code}', currencyCode)),
          ),
        );
      }
    }
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
          const SizedBox(width: 12),
          Text(
            AppStrings.newCurrencyTitle.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
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
              child: GestureDetector(
                onTap: () {
                  if (_currencyFocusNode.hasFocus) {
                    _clearFocusAndSelection();
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          _buildFeatureInfoCard(isDark),
                          if (_failedToFetchCurrencies) ...[
                            const SizedBox(height: 16),
                            _buildWarningCard(isDark),
                          ],
                          const SizedBox(height: 24),
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
                          if (_selectedCurrency != null && !_isCustomMode) ...[                          
                            const SizedBox(height: 16),
                            _buildCurrencyInfoCard(isDark),
                          ],
                          const SizedBox(height: 24),
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
                              onPressed: _selectedCurrency != null ? _createCurrencyChoice : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedCurrency != null
                                    ? Colors.transparent
                                    : (isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade200),
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
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    AppStrings.save.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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

  Widget _buildFeatureInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1F3A), const Color(0xFF0F1329)]
              : [Colors.white, Colors.grey.shade50],
        ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400.withOpacity(0.1), Colors.purple.shade400.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.add_card_rounded,
              size: 56,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.addNewCurrency.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.trackMultipleCurrencies.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.swap_horiz_rounded,
            title: AppStrings.easySwitching.tr,
            description: AppStrings.easySwitchingDesc.tr,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.trending_up_rounded,
            title: AppStrings.trackSeparately.tr,
            description: AppStrings.trackSeparatelyDesc.tr,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.account_balance_wallet_rounded,
            title: AppStrings.manageAssets.tr,
            description: AppStrings.manageAssetsDesc.tr,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400.withOpacity(0.15), Colors.purple.shade400.withOpacity(0.15)],
            ),
            borderRadius: BorderRadius.circular(10),
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
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontSize: 12,
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
                    colors: [Colors.blue.shade400.withOpacity(0.1), Colors.purple.shade400.withOpacity(0.1)],
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
                AppStrings.selectCurrency.tr,
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
                final name = CurrencyService.getCurrencyName(currency).toLowerCase();
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
                  hintText: _isLoadingCurrencies ? AppStrings.loadingCurrenciesText.tr : AppStrings.searchCurrenciesText.tr,
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
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final currency = options.elementAt(index);
                        final name = CurrencyService.getCurrencyName(currency);
                        final symbol = CurrencyService.getCurrencySymbol(currency);

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
                                      colors: [Colors.blue.shade400.withOpacity(0.1), Colors.purple.shade400.withOpacity(0.1)],
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
                                                  ? AppColors
                                                      .darkTextSecondary
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightPrimary.withOpacity(0.1),
            AppColors.lightSecondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightPrimary.withOpacity(0.2),
          width: 1.5,
        ),
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
                    colors: [AppColors.lightPrimary, AppColors.lightSecondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.currencyDetails.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            AppStrings.code.tr,
            _currencyCodeController.text,
            Icons.code_rounded,
            isDark,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            AppStrings.name.tr,
            _currencyNameController.text,
            Icons.label_outline_rounded,
            isDark,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            AppStrings.symbol.tr,
            _currencySymbolController.text,
            Icons.currency_exchange_rounded,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.lightPrimary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
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
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
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
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
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
          AppStrings.chooseFromCurrenciesButton.tr,
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
                    colors: [Colors.blue.shade400.withOpacity(0.1), Colors.purple.shade400.withOpacity(0.1)],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          final isCodeValid = _customCodeFieldKey.currentState?.isValid ?? false;
          final isNameValid = _customNameFieldKey.currentState?.isValid ?? false;
          final isSymbolValid = _customSymbolFieldKey.currentState?.isValid ?? false;
          
          _selectedCurrency = (isCodeValid && isNameValid && isSymbolValid) ? 'CUSTOM' : null;
        });
      },
    );
  }
}
