import 'package:asset_it/core/utils/number_formatter.dart';
import 'package:asset_it/data/entities/finance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/enums/asset_enums.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/features/assets/presentation/providers/assets_provider.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/core/services/currency_service.dart';
import 'package:provider/provider.dart';

class AssetScreen extends StatefulWidget {
  final Asset? assetToEdit;

  const AssetScreen({super.key, this.assetToEdit});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _isFormValid = false;

  late TextEditingController _initialValueController;
  late TextEditingController _notesController;

  late TextEditingController _goldGramsController;
  late TextEditingController _goldPricePerGramController;

  late TextEditingController _stockSymbolController;
  late TextEditingController _stockSharesController;
  late TextEditingController _stockPricePerShareController;

  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountTypeController;

  late TextEditingController _creditLimitController;
  late TextEditingController _creditUsedController;

  late TextEditingController _loanInterestRateController;

  late TextEditingController _currencyAmountController;
  late TextEditingController _purchaseRateController;

  final _initialValueFieldKey = GlobalKey<FormFieldState>();
  final _goldGramsFieldKey = GlobalKey<FormFieldState>();
  final _goldPricePerGramFieldKey = GlobalKey<FormFieldState>();
  final _stockSymbolFieldKey = GlobalKey<FormFieldState>();
  final _stockSharesFieldKey = GlobalKey<FormFieldState>();
  final _stockPricePerShareFieldKey = GlobalKey<FormFieldState>();
  final _bankNameFieldKey = GlobalKey<FormFieldState>();
  final _bankAccountTypeFieldKey = GlobalKey<FormFieldState>();
  final _creditLimitFieldKey = GlobalKey<FormFieldState>();
  final _creditUsedFieldKey = GlobalKey<FormFieldState>();
  final _loanInterestRateFieldKey = GlobalKey<FormFieldState>();
  final _currencyAmountFieldKey = GlobalKey<FormFieldState>();
  final _purchaseRateFieldKey = GlobalKey<FormFieldState>();
  late TextEditingController _currencySearchController;
  late FocusNode _currencyFocusNode;
  late TextEditingController _assetTypeSearchController;
  late FocusNode _assetTypeFocusNode;
  late TextEditingController _goldTypeSearchController;
  late FocusNode _goldTypeFocusNode;
  late TextEditingController _stockSearchController;
  late FocusNode _stockFocusNode;

  AssetType _selectedType = AssetType.cash;
  String _selectedGoldKarat = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = '';
  List<String> _availableCurrencies = [];
  bool _isLoadingCurrencies = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAssetData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePricesFromFinance();
      if (widget.assetToEdit != null) {
        _validateForm();
      }
    });
  }

  void _initializeControllers() {
    _initialValueController = TextEditingController();
    _notesController = TextEditingController();

    _goldGramsController = TextEditingController();
    _goldPricePerGramController = TextEditingController();

    _stockSymbolController = TextEditingController();
    _stockSharesController = TextEditingController();
    _stockPricePerShareController = TextEditingController();

    _bankNameController = TextEditingController();
    _bankAccountTypeController = TextEditingController();

    _creditLimitController = TextEditingController();
    _creditUsedController = TextEditingController();

    _loanInterestRateController = TextEditingController();

    _currencyAmountController = TextEditingController();
    _purchaseRateController = TextEditingController();
    _currencySearchController = TextEditingController();
    _currencyFocusNode = FocusNode();
    _assetTypeSearchController = TextEditingController();
    _assetTypeFocusNode = FocusNode();
    _goldTypeSearchController = TextEditingController();
    _goldTypeFocusNode = FocusNode();
    _stockSearchController = TextEditingController();
    _stockFocusNode = FocusNode();

    _initialValueController.addListener(_validateForm);
    _goldGramsController.addListener(_validateForm);
    _goldPricePerGramController.addListener(_validateForm);
    _stockSymbolController.addListener(_validateForm);
    _stockSharesController.addListener(_validateForm);
    _stockPricePerShareController.addListener(_validateForm);
    _bankNameController.addListener(_validateForm);
    _bankAccountTypeController.addListener(_validateForm);
    _creditLimitController.addListener(_validateForm);
    _creditUsedController.addListener(_validateForm);
    _loanInterestRateController.addListener(_validateForm);
    _currencyAmountController.addListener(_validateForm);
    _purchaseRateController.addListener(_validateForm);

    _fetchAvailableCurrencies();
  }

  void _validateForm() {
    bool isValid = false;

    switch (_selectedType) {
      case AssetType.gold:
        final isKaratValid = _selectedGoldKarat.isNotEmpty;
        final isGramsValid = _goldGramsFieldKey.currentState?.isValid ?? false;
        final isPriceValid =
            _goldPricePerGramFieldKey.currentState?.isValid ?? false;
        isValid = isKaratValid && isGramsValid && isPriceValid;
        break;
      case AssetType.stock:
        final isSymbolValid = _stockSymbolFieldKey.currentState?.isValid ?? false;
        final isSharesValid =
            _stockSharesFieldKey.currentState?.isValid ?? false;
        final isPriceValid =
            _stockPricePerShareFieldKey.currentState?.isValid ?? false;
        isValid = isSymbolValid && isSharesValid && isPriceValid;
        break;
      case AssetType.bankAccount:
        final isBankNameValid =
            _bankNameFieldKey.currentState?.isValid ?? false;
        final isBalanceValid =
            _initialValueFieldKey.currentState?.isValid ?? false;
        isValid = isBankNameValid && isBalanceValid;
        break;
      case AssetType.creditCard:
        final isBankNameValid =
            _bankNameFieldKey.currentState?.isValid ?? false;
        final isLimitValid =
            _creditLimitFieldKey.currentState?.isValid ?? false;
        final isUsedValid = _creditUsedFieldKey.currentState?.isValid ?? false;
        isValid = isBankNameValid && isLimitValid && isUsedValid;
        break;
      case AssetType.loan:
        final isLoanAmountValid =
            _initialValueFieldKey.currentState?.isValid ?? false;
        isValid = isLoanAmountValid;
        break;
      case AssetType.currency:
        final isCurrencyValid = _selectedCurrency.isNotEmpty;
        final isAmountValid =
            _currencyAmountFieldKey.currentState?.isValid ?? false;
        final isPurchaseRateValid =
            _purchaseRateFieldKey.currentState?.isValid ?? false;
        isValid = isCurrencyValid && isAmountValid && isPurchaseRateValid;
        break;
      case AssetType.cash:
        final isCashAmountValid =
            _initialValueFieldKey.currentState?.isValid ?? false;
        isValid = isCashAmountValid;
        break;
      default:
        isValid = _initialValueController.text.trim().isNotEmpty;
    }

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _initializePricesFromFinance() {
    if (widget.assetToEdit == null) {
      final financeProvider =
          Provider.of<FinanceProvider>(context, listen: false);

      if (_selectedType == AssetType.gold) {
        final goldPrice = financeProvider.getGoldFinance(_selectedGoldKarat);

        if (goldPrice! > 0) {
          setState(() {
            _goldPricePerGramController.text = goldPrice.toStringAsFixed(2);
          });
        } else {
          final goldFinances = financeProvider.goldFinances;
          if (goldFinances.isNotEmpty) {
            setState(() {
              _goldPricePerGramController.text =
                  goldFinances.first.value.toStringAsFixed(2);
            });
          }
        }
      }
    }
  }

  void _loadAssetData() {
    if (widget.assetToEdit != null) {
      final asset = widget.assetToEdit!;
      _initialValueController.text = asset.initialValue.toString();
      _notesController.text = asset.notes ?? '';
      _selectedType = asset.type;
      _selectedDate = asset.dateAdded;
      _assetTypeSearchController.text = asset.type.displayName;

      if (asset.type == AssetType.gold) {
        _selectedGoldKarat = asset.goldKarat ?? '24k';
        _goldTypeSearchController.text = asset.goldKarat ?? '24k';
        _goldGramsController.text = asset.goldGrams?.toString() ?? '';
        _goldPricePerGramController.text =
            asset.goldPricePerGram?.toString() ?? '';
      } else if (asset.type == AssetType.stock) {
        _stockSymbolController.text = asset.stockSymbol ?? '';
        _stockSearchController.text = asset.stockSymbol ?? '';
        _stockSharesController.text = asset.stockShares?.toString() ?? '';
        _stockPricePerShareController.text =
            asset.stockPricePerShare?.toString() ?? '';
      } else if (asset.type == AssetType.bankAccount) {
        _bankNameController.text = asset.bankName ?? '';
        _bankAccountTypeController.text = asset.bankAccountType ?? '';
      } else if (asset.type == AssetType.creditCard) {
        _bankNameController.text = asset.bankName ?? '';
        _creditLimitController.text = asset.creditLimit?.toString() ?? '';
        _creditUsedController.text = asset.creditUsed?.toString() ?? '';
      } else if (asset.type == AssetType.loan) {
        _loanInterestRateController.text =
            asset.loanInterestRate?.toString() ?? '';
      } else if (asset.type == AssetType.currency ||
          asset.type == AssetType.cash) {
        _selectedCurrency = asset.currency ?? 'USD';
        _currencySearchController.text = _selectedCurrency;
        _currencyAmountController.text = asset.currencyAmount?.toString() ?? '';
        _purchaseRateController.text = asset.purchaseRate?.toString() ?? '';
      }
    }
  }

  Future<void> _fetchAvailableCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    final financeProvider = context.read<FinanceProvider>();
    final currencyFinances = financeProvider.currencyFinances;

    final currencies = currencyFinances.map((f) => f.code).toList();
    
    setState(() {
      _availableCurrencies = currencies;
      _isLoadingCurrencies = false;
    });
  }

  @override
  void dispose() {
    _initialValueController.dispose();
    _notesController.dispose();
    _goldGramsController.dispose();
    _goldPricePerGramController.dispose();
    _stockSymbolController.dispose();
    _stockSharesController.dispose();
    _stockPricePerShareController.dispose();
    _bankNameController.dispose();
    _bankAccountTypeController.dispose();
    _creditLimitController.dispose();
    _creditUsedController.dispose();
    _loanInterestRateController.dispose();
    _currencyAmountController.dispose();
    _purchaseRateController.dispose();
    _currencySearchController.dispose();
    _currencyFocusNode.dispose();
    _assetTypeSearchController.dispose();
    _assetTypeFocusNode.dispose();
    _goldTypeSearchController.dispose();
    _goldTypeFocusNode.dispose();
    _stockSearchController.dispose();
    _stockFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.assetToEdit != null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark, isEdit),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildBasicInfoCard(isDark),
                          const SizedBox(height: 16),
                          _buildTypeSpecificFields(isDark),
                          const SizedBox(height: 16),
                          _buildAdditionalInfoCard(isDark),
                          const SizedBox(height: 15),
                          _buildSaveButton(isDark, isEdit),
                          const SizedBox(height: 30),
                        ],
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isEdit) {
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
            color: Colors.black.withOpacity(0.15),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isEdit ? AppStrings.updateAsset.tr : AppStrings.newAsset.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (isEdit)
            _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: _confirmDelete,
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    GlobalKey<FormFieldState>? fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
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
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters ??
                (keyboardType == TextInputType.number
                    ? [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ]
                    : null),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint ?? label,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF0F1329) : Colors.grey.shade100,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue.shade400,
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
            onChanged: (value) {
              if (fieldKey != null) {
                fieldKey.currentState?.validate();
              }
              if (onChanged != null) {
                onChanged(value);
              }
              _validateForm();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(bool isDark) {
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
                  Icons.category,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.assetType.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RawAutocomplete<AssetType>(
            textEditingController: _assetTypeSearchController,
            focusNode: _assetTypeFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return AssetType.values;
              }
              return AssetType.values.where((type) {
                return type.displayName
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (AssetType selection) {
              setState(() {
                _selectedType = selection;
                _assetTypeSearchController.text = selection.displayName;
              });
              _validateForm();
              HapticFeedback.lightImpact();
            },
            displayStringForOption: (AssetType option) => option.displayName,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                enabled: widget.assetToEdit == null,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.searchAssetTypes.tr,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 20,
                            color:
                                isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                          onPressed: () {
                            controller.clear();
                            focusNode.unfocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF0F1329) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 76,
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
                        final type = options.elementAt(index);
                        final icon = _getTypeIcon(type);
                        final color = _getTypeColor(type);

                        return InkWell(
                          onTap: () => onSelected(type),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    type.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey.shade800,
                                    ),
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

  Widget _buildDatePicker(bool isDark) {
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
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.dateAdded.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1329) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildTypeDropdown(isDark),
      ],
    );
  }

  Widget _buildTypeSpecificFields(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedType),
        child: _buildSpecificFields(isDark),
      ),
    );
  }

  Widget _buildSpecificFields(bool isDark) {
    switch (_selectedType) {
      case AssetType.gold:
        return _buildGoldFields(isDark);
      case AssetType.stock:
        return _buildStockFields(isDark);
      case AssetType.bankAccount:
        return _buildBankAccountFields(isDark);
      case AssetType.creditCard:
        return _buildCreditCardFields(isDark);
      case AssetType.loan:
        return _buildLoanFields(isDark);
      case AssetType.currency:
        return _buildCurrencyFields(isDark);
      case AssetType.cash:
        return _buildCashFields(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoldFields(bool isDark) {
    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);
    final goldFinances = financeProvider.goldFinances;

    return Column(
      children: [
        Container(
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
                      Icons.diamond_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gold Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RawAutocomplete<Finance>(
                textEditingController: _goldTypeSearchController,
                focusNode: _goldTypeFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return goldFinances;
                  }
                  return goldFinances.where((gold) {
                    final searchLower = textEditingValue.text.toLowerCase();
                    final name = (gold.name ?? gold.code).toLowerCase();
                    return gold.code.toLowerCase().contains(searchLower) ||
                        name.contains(searchLower);
                  });
                },
                onSelected: (Finance selection) {
                  setState(() {
                    _selectedGoldKarat = selection.code;
                    _goldTypeSearchController.text =
                        selection.name ?? selection.code;
                  });
                  _validateForm();
                  HapticFeedback.lightImpact();
                },
                displayStringForOption: (Finance option) =>
                    option.name ?? option.code,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled:
                        widget.assetToEdit == null && goldFinances.isNotEmpty,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: goldFinances.isEmpty
                          ? 'No gold available'
                          : 'Search gold types',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                              onPressed: () {
                                controller.clear();
                                focusNode.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F1329)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade400,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 76,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1A1F3A) : Colors.white,
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
                            final gold = options.elementAt(index);

                            return InkWell(
                              onTap: () => onSelected(gold),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.diamond,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            gold.name ?? gold.code,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                          Text(
                                            gold.code,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade600,
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
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _goldGramsFieldKey,
          controller: _goldGramsController,
          label: AppStrings.grams.tr,
          icon: Icons.scale,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter grams';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _goldPricePerGramFieldKey,
          controller: _goldPricePerGramController,
          label: AppStrings.pricePerGram.tr,
          icon: Icons.attach_money,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter price per gram';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStockFields(bool isDark) {
    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);
    final stockFinances = financeProvider.stockFinances;

    return Column(
      children: [
        Container(
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
                      Icons.show_chart,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Stock Symbol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RawAutocomplete<Finance>(
                textEditingController: _stockSearchController,
                focusNode: _stockFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return stockFinances;
                  }
                  return stockFinances.where((stock) {
                    final searchLower = textEditingValue.text.toLowerCase();
                    final name = (stock.name ?? stock.code).toLowerCase();
                    return stock.code.toLowerCase().contains(searchLower) ||
                        name.contains(searchLower);
                  });
                },
                onSelected: (Finance selection) {
                  setState(() {
                    _stockSymbolController.text = selection.code;
                    _stockSearchController.text = selection.code;
                  });
                  _stockSymbolFieldKey.currentState?.validate();
                  _validateForm();
                  HapticFeedback.lightImpact();
                },
                displayStringForOption: (Finance option) => option.code,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    key: _stockSymbolFieldKey,
                    controller: controller,
                    focusNode: focusNode,
                    enabled:
                        widget.assetToEdit == null && stockFinances.isNotEmpty,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: stockFinances.isEmpty
                          ? 'No stocks available'
                          : 'Search stocks',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                              onPressed: () {
                                controller.clear();
                                focusNode.unfocus();
                                setState(() {
                                  _stockSymbolController.clear();
                                });
                                _validateForm();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F1329)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade400,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select a stock symbol';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _stockSymbolController.text = value;
                      _stockSymbolFieldKey.currentState?.validate();
                      _validateForm();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 76,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1A1F3A) : Colors.white,
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
                            final stock = options.elementAt(index);

                            return InkWell(
                              onTap: () => onSelected(stock),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.trending_up,
                                        color: Colors.purple,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stock.code,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                          if (stock.name != null)
                                            Text(
                                              stock.name!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white60
                                                    : Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _stockSharesFieldKey,
          controller: _stockSharesController,
          label: AppStrings.shares.tr,
          icon: Icons.stacked_bar_chart_outlined,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter shares';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _stockPricePerShareFieldKey,
          controller: _stockPricePerShareController,
          label: AppStrings.pricePerShare.tr,
          icon: Icons.attach_money,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter price per share';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBankAccountFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          fieldKey: _bankNameFieldKey,
          controller: _bankNameController,
          label: AppStrings.bankName.tr,
          icon: Icons.account_balance,
          isDark: isDark,
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _bankAccountTypeFieldKey,
          controller: _bankAccountTypeController,
          label: 'Account Type',
          icon: Icons.account_balance_wallet,
          isDark: isDark,
          maxLength: 30,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _initialValueFieldKey,
          controller: _initialValueController,
          label: 'Balance',
          icon: Icons.account_balance_wallet_outlined,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 15,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter balance';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCreditCardFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          fieldKey: _bankNameFieldKey,
          controller: _bankNameController,
          label: AppStrings.bankName.tr,
          icon: Icons.account_balance,
          isDark: isDark,
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _creditLimitFieldKey,
          controller: _creditLimitController,
          label: AppStrings.limit.tr,
          icon: Icons.credit_score,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 15,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter credit limit';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _creditUsedFieldKey,
          controller: _creditUsedController,
          label: AppStrings.used.tr,
          icon: Icons.credit_card,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 15,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter used amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoanFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          fieldKey: _initialValueFieldKey,
          controller: _initialValueController,
          label: 'Loan Amount',
          icon: Icons.payments_outlined,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 15,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter loan amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _loanInterestRateFieldKey,
          controller: _loanInterestRateController,
          label: 'Interest Rate (%)',
          icon: Icons.percent,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 6,
        ),
      ],
    );
  }

  Widget _buildCurrencyFields(bool isDark) {
    return Column(
      children: [
        Container(
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
                      Icons.attach_money,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.currency.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    _calculateCurrencyValue();
                  });
                  _validateForm();
                  HapticFeedback.lightImpact();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled:
                        widget.assetToEdit == null && !_isLoadingCurrencies && _availableCurrencies.isNotEmpty,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: _isLoadingCurrencies
                          ? 'Loading currencies...'
                          : _availableCurrencies.isEmpty
                              ? 'No available currencies'
                              : 'Search currencies',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      prefixIcon: _isLoadingCurrencies
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade400,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.currency_exchange_rounded,
                              color: Colors.blue.shade400,
                              size: 20,
                            ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                              onPressed: () {
                                controller.clear();
                                _currencyFocusNode.unfocus();
                                setState(() {
                                  _selectedCurrency = 'USD';
                                  _calculateCurrencyValue();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F1329)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade400,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 76,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1A1F3A) : Colors.white,
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
                            final name =
                                CurrencyService.getCurrencyName(currency);
                            final fullSymbol =
                                CurrencyService.getCurrencySymbol(currency);
                            final symbol = fullSymbol.substring(0, 
                                fullSymbol.length > 3 ? 3 : fullSymbol.length);

                            return InkWell(
                              onTap: () => onSelected(currency),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade400
                                                .withOpacity(0.1),
                                            Colors.purple.shade400
                                                .withOpacity(0.1)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          symbol,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade600,
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
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _currencyAmountFieldKey,
          controller: _currencyAmountController,
          label: 'Amount',
          icon: Icons.numbers,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 15,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (_) => _calculateCurrencyValue(),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          fieldKey: _purchaseRateFieldKey,
          controller: _purchaseRateController,
          label: 'Purchase Rate',
          icon: Icons.currency_exchange,
          isDark: isDark,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter purchase rate';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (_) => _calculateCurrencyValue(),
        ),
      ],
    );
  }

  Widget _buildCashFields(bool isDark) {
    return _buildTextField(
      fieldKey: _initialValueFieldKey,
      controller: _initialValueController,
      label: 'Cash Amount',
      icon: Icons.payments_outlined,
      isDark: isDark,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      maxLength: 15,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter cash amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  void _calculateCurrencyValue() {
    final amount = double.tryParse(_currencyAmountController.text) ?? 0;
    final rate = double.tryParse(_purchaseRateController.text);

    if (amount > 0 && rate != null && rate > 0) {
      setState(() {
        _initialValueController.text = (amount * rate).toStringAsFixed(2);
      });
    } else if (amount > 0) {
      setState(() {
        _initialValueController.text = amount.toStringAsFixed(2);
      });
    }
  }

  double _calculateInitialValue() {
    switch (_selectedType) {
      case AssetType.gold:
        final grams = double.tryParse(_goldGramsController.text) ?? 0;
        final pricePerGram =
            double.tryParse(_goldPricePerGramController.text) ?? 0;
        return grams * pricePerGram;

      case AssetType.stock:
        final shares = double.tryParse(_stockSharesController.text) ?? 0;
        final pricePerShare =
            double.tryParse(_stockPricePerShareController.text) ?? 0;
        return shares * pricePerShare;

      case AssetType.creditCard:
        final used = double.tryParse(_creditUsedController.text) ?? 0;
        return -used;

      case AssetType.loan:
        final loanAmount = double.tryParse(_initialValueController.text) ?? 0;
        return -loanAmount;

      case AssetType.currency:
        final amount = double.tryParse(_currencyAmountController.text) ?? 0;
        final rate = double.tryParse(_purchaseRateController.text);
        if (rate != null && rate > 0) {
          return amount * rate;
        }
        return amount;

      case AssetType.bankAccount:
      case AssetType.cash:
      default:
        return double.tryParse(_initialValueController.text) ?? 0;
    }
  }

  Widget _buildAdditionalInfoCard(bool isDark) {
    return Column(
      children: [
        _buildDatePicker(isDark),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _notesController,
          label: AppStrings.notes.tr,
          icon: Icons.note_outlined,
          isDark: isDark,
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark, bool isEdit) {
    final isEnabled = _isFormValid && !_isLoading;

    return Container(
      width: double.infinity,
      decoration: isEnabled
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
        onPressed: isEnabled ? _saveAsset : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? Colors.transparent
              : (isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade200),
          foregroundColor: isEnabled
              ? Colors.white
              : (isDark ? Colors.white38 : Colors.grey.shade400),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                isEdit ? "Update" : "Save",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        return Colors.blue;
      case AssetType.gold:
        return Colors.amber;
      case AssetType.bankAccount:
        return Colors.teal;
      case AssetType.cash:
        return Colors.green;
      case AssetType.creditCard:
        return Colors.orange;
      case AssetType.loan:
        return Colors.red;
      case AssetType.stock:
        return Colors.purple;
    }
  }

  Future<void> _saveAsset() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final currencyChoiceProvider =
          Provider.of<CurrencyChoiceProvider>(context, listen: false);
      if (currencyChoiceProvider.activeCurrencyChoice == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.pleaseSetupCurrencyProfile.tr),
        ));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final assetProvider = Provider.of<AssetsProvider>(context, listen: false);

      Map<String, dynamic>? details;

      if (_selectedType == AssetType.gold) {
        details = {
          'karat': _selectedGoldKarat,
          'grams': double.tryParse(_goldGramsController.text) ?? 0,
          'pricePerGram':
              double.tryParse(_goldPricePerGramController.text) ?? 0,
        };
      } else if (_selectedType == AssetType.stock) {
        details = {
          'symbol': _stockSymbolController.text,
          'shares': double.tryParse(_stockSharesController.text) ?? 0,
          'pricePerShare':
              double.tryParse(_stockPricePerShareController.text) ?? 0,
        };
      } else if (_selectedType == AssetType.bankAccount) {
        details = {
          'bankName': _bankNameController.text,
          'accountType': _bankAccountTypeController.text,
        };
      } else if (_selectedType == AssetType.creditCard) {
        details = {
          'bankName': _bankNameController.text,
          'creditLimit': double.tryParse(_creditLimitController.text) ?? 0,
          'used': double.tryParse(_creditUsedController.text) ?? 0,
        };
      } else if (_selectedType == AssetType.loan) {
        details = {
          'interestRate':
              double.tryParse(_loanInterestRateController.text) ?? 0,
        };
      } else if (_selectedType == AssetType.currency ||
          _selectedType == AssetType.cash) {
        details = {
          'currency': _selectedCurrency,
          'currencyAmount': double.tryParse(_currencyAmountController.text),
          'purchaseRate': double.tryParse(_purchaseRateController.text),
        };
      }

      final asset = Asset(
        id: widget.assetToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        type: _selectedType,
        initialValue: _calculateInitialValue(),
        dateAdded: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        details: details,
        baseCurrency: widget.assetToEdit?.baseCurrency,
        sortOrder: widget.assetToEdit?.sortOrder ?? 0,
      );

      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final message = widget.assetToEdit == null
          ? AppStrings.assetAddedSuccessfully.tr
          : AppStrings.assetUpdatedSuccessfully.tr;

      final success = widget.assetToEdit == null
          ? await assetProvider.addAsset(asset)
          : await assetProvider.updateAsset(asset);

      setState(() {
        _isLoading = false;
      });

      if (mounted && success) {
        navigator.pop();
        Future.microtask(() {
          scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(message)));
        });
      } else if (mounted) {
        final errorMessage = assetProvider.error ??
            (widget.assetToEdit == null ? AppStrings.failedToAddAsset.tr : AppStrings.failedToUpdateAsset.tr);

        scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
            ));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${AppStrings.errorOccurred.tr}: ${e.toString()}'),
        ));
      }
    }
  }

  Widget _buildAssetSpecificDeleteInfo(bool isDark) {
    if (widget.assetToEdit == null) return const SizedBox.shrink();

    final asset = widget.assetToEdit!;

    switch (asset.type) {
      case AssetType.gold:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Gold - '),
                TextSpan(
                  text:
                      '${asset.goldKarat ?? ""} (${asset.goldGrams ?? 0} grams)',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );

      case AssetType.stock:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Stock - '),
                TextSpan(
                  text:
                      '${asset.stockSymbol ?? ""} (${asset.stockShares ?? 0} shares)',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );

      case AssetType.bankAccount:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Bank - '),
                TextSpan(
                  text: asset.bankName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );

      case AssetType.creditCard:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Credit Card - '),
                TextSpan(
                  text: asset.bankName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );

      case AssetType.loan:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Loan - '),
                TextSpan(
                  text: NumberFormatter.formatWithSymbol(asset.initialValue.abs()),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );

      case AssetType.currency:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Currency - '),
                TextSpan(
                  text: asset.currency ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );

      case AssetType.cash:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Amount - '),
                TextSpan(
                  text: '${asset.initialValue}',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
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
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Asset',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  Text(
                    'Are you sure you want to delete',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  _buildAssetSpecificDeleteInfo(isDark),
                ],
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
                          'Cancel',
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
                            Colors.blue.shade400,
                            Colors.purple.shade400
                          ],
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
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
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

    if (confirmed == true && widget.assetToEdit != null) {
      setState(() {
        _isDeleting = true;
      });

      final assetProvider = Provider.of<AssetsProvider>(context, listen: false);
      final success = await assetProvider.deleteAsset(widget.assetToEdit!.id);

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.failedToDeleteAsset.tr),
            ),
          );
        }
      }
    }
  }
}
