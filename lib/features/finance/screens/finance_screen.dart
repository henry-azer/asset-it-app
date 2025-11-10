import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/core/enums/finance_enums.dart';
import 'package:asset_it/data/entities/finance.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/core/services/currency_service.dart';
import 'package:asset_it/features/assets/presentation/providers/assets_provider.dart';
import 'package:asset_it/core/enums/asset_enums.dart';
import 'package:uuid/uuid.dart';

class FinanceScreen extends StatefulWidget {
  final FinanceType financeType;
  final Finance? finance;

  const FinanceScreen({
    super.key,
    required this.financeType,
    this.finance,
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _codeFieldKey = GlobalKey<FormFieldState>();
  final _symbolFieldKey = GlobalKey<FormFieldState>();
  final _valueFieldKey = GlobalKey<FormFieldState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _valueController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _symbolFocusNode = FocusNode();
  final _valueFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.finance != null) {
      _codeController.text = widget.finance!.code;
      _nameController.text = widget.finance!.name ?? '';
      _valueController.text = widget.finance!.value.toStringAsFixed(2);
      if (widget.financeType == FinanceType.currency) {
        _symbolController.text =
            CurrencyService.getCurrencySymbol(widget.finance!.code);
      }
      _isFormValid = true;
    }
    _addValidationListeners();
  }

  void _addValidationListeners() {
    _nameController.addListener(_validateForm);
    _codeController.addListener(_validateForm);
    _symbolController.addListener(_validateForm);
    _valueController.addListener(_validateForm);
  }

  void _validateForm() {
    bool isValid = true;
    isValid = isValid && (_nameFieldKey.currentState?.isValid ?? false);
    isValid = isValid && (_codeFieldKey.currentState?.isValid ?? false);
    if (widget.financeType == FinanceType.currency) {
      isValid = isValid && (_symbolFieldKey.currentState?.isValid ?? false);
    }
    isValid = isValid && (_valueFieldKey.currentState?.isValid ?? false);

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _valueController.dispose();
    _codeFocusNode.dispose();
    _nameFocusNode.dispose();
    _symbolFocusNode.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveFinance() async {
    if (widget.finance == null) {
      bool isValid = true;
      isValid = _nameFieldKey.currentState?.validate() ?? false;
      isValid = _codeFieldKey.currentState?.validate() ?? false;
      if (widget.financeType == FinanceType.currency) {
        isValid = _symbolFieldKey.currentState?.validate() ?? false;
      }
      isValid = _valueFieldKey.currentState?.validate() ?? false;
      
      if (!isValid) return;
    }

    setState(() {
      _isLoading = true;
    });

    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);
    final currencyChoiceProvider =
        Provider.of<CurrencyChoiceProvider>(context, listen: false);
    final baseCurrency = currencyChoiceProvider.getActiveCurrencyCode();

    final code = _codeController.text.trim().toUpperCase();
    final existingFinance = financeProvider.getFinanceByCodeAndBaseCurrency(
      code,
      baseCurrency,
      type: widget.financeType,
    );

    if (existingFinance != null && existingFinance.id != widget.finance?.id) {
      String message;
      switch (widget.financeType) {
        case FinanceType.currency:
          message = AppStrings.currencyAlreadyExists.tr.replaceAll('{code}', code);
          break;
        case FinanceType.gold:
          message = AppStrings.goldAlreadyExists.tr.replaceAll('{code}', code);
          break;
        case FinanceType.stock:
          message = AppStrings.stockAlreadyExists.tr.replaceAll('{code}', code);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final finance = Finance(
      id: widget.finance?.id ?? const Uuid().v4(),
      type: widget.financeType,
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      value: double.parse(_valueController.text),
      baseCurrency: baseCurrency,
      lastUpdated: DateTime.now(),
    );

    bool success;
    if (widget.finance != null) {
      success = await financeProvider.updateFinance(finance);
    } else {
      success = await financeProvider.addFinance(finance);
    }

    setState(() {
      _isLoading = false;
    });
    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.failedToSaveFinance.tr),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.finance != null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, isEditing),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameField(isDark),
                    const SizedBox(height: 10),
                    _buildCodeField(isDark),
                    const SizedBox(height: 10),
                    if (widget.financeType == FinanceType.currency) ...[
                      _buildSymbolField(isDark),
                      const SizedBox(height: 10),
                    ],
                    _buildValueField(isDark),
                    const SizedBox(height: 15),
                    _buildSaveButton(isDark, isEditing),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isEditing) {
    String title;

    switch (widget.financeType) {
      case FinanceType.currency:
        title = isEditing ? AppStrings.updateCurrency.tr : AppStrings.newCurrency.tr;
        break;
      case FinanceType.gold:
        title = isEditing ? AppStrings.updateGold.tr : AppStrings.newGold.tr;
        break;
      case FinanceType.stock:
        title = isEditing ? AppStrings.updateStock.tr : AppStrings.newStock.tr;
        break;
    }

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
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (isEditing) ...[
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: _confirmDelete,
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymbolField(bool isDark) {
    return _buildTextField(
      fieldKey: _symbolFieldKey,
      controller: _symbolController,
      focusNode: _symbolFocusNode,
      label: AppStrings.currencySymbol.tr,
      hint: '\$',
      isDark: isDark,
      icon: Icons.currency_exchange_rounded,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.pleaseEnterCurrencySymbol.tr;
        }
        return null;
      },
      onChanged: (value) {
        _symbolFieldKey.currentState?.validate();
        _validateForm();
      },
    );
  }

  Widget _buildCodeField(bool isDark) {
    return _buildTextField(
      fieldKey: _codeFieldKey,
      controller: _codeController,
      focusNode: _codeFocusNode,
      label:
          widget.financeType == FinanceType.currency ? AppStrings.currencyCode.tr : AppStrings.code.tr,
      hint: widget.financeType == FinanceType.currency
          ? AppStrings.currencyCodeHint.tr
          : widget.financeType == FinanceType.gold
              ? AppStrings.goldCodeHint.tr
              : AppStrings.stockCodeHint.tr,
      isDark: isDark,
      icon: Icons.code_rounded,
      enabled: widget.finance == null,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.pleaseEnterCode.tr;
        }
        return null;
      },
      onChanged: (value) {
        _codeFieldKey.currentState?.validate();
        _validateForm();
      },
    );
  }

  Widget _buildNameField(bool isDark) {
    return _buildTextField(
      fieldKey: _nameFieldKey,
      controller: _nameController,
      focusNode: _nameFocusNode,
      label: AppStrings.name.tr,
      hint: widget.financeType == FinanceType.currency
          ? AppStrings.usDollar.tr
          : widget.financeType == FinanceType.gold
              ? AppStrings.gold24k.tr
              : AppStrings.appleInc.tr,
      isDark: isDark,
      icon: Icons.label_outline_rounded,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.pleaseEnterName.tr;
        }
        return null;
      },
      onChanged: (value) {
        _nameFieldKey.currentState?.validate();
        _validateForm();
      },
    );
  }

  Widget _buildValueField(bool isDark) {
    return _buildTextField(
      fieldKey: _valueFieldKey,
      controller: _valueController,
      focusNode: _valueFocusNode,
      label: AppStrings.value.tr,
      hint: '0.00',
      isDark: isDark,
      icon: Icons.attach_money_rounded,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.pleaseEnterValue.tr;
        }
        if (double.tryParse(value) == null) {
          return AppStrings.pleaseEnterValidNumber.tr;
        }
        return null;
      },
      onChanged: (value) {
        _valueFieldKey.currentState?.validate();
        _validateForm();
      },
    );
  }

  Widget _buildTextField({
    required GlobalKey<FormFieldState> fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isDark,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark, bool isEditing) {
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
        onPressed: isEnabled ? _saveFinance : null,
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
                isEditing ? AppStrings.update.tr : AppStrings.save.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  bool _hasLinkedAssets() {
    if (widget.finance == null) return false;

    final assetsProvider = Provider.of<AssetsProvider>(context, listen: false);
    final assets = assetsProvider.assets;
    final financeCode = widget.finance!.code;

    switch (widget.financeType) {
      case FinanceType.currency:
        return assets.any((asset) =>
            asset.type == AssetType.currency &&
            asset.currency?.toUpperCase() == financeCode.toUpperCase());

      case FinanceType.gold:
        return assets.any((asset) =>
            asset.type == AssetType.gold &&
            asset.goldKarat != null &&
            _normalizeGoldCode(asset.goldKarat!) == _normalizeGoldCode(financeCode));

      case FinanceType.stock:
        return assets.any((asset) =>
            asset.type == AssetType.stock &&
            asset.stockSymbol?.toUpperCase() == financeCode.toUpperCase());
    }
  }

  String _normalizeGoldCode(String code) {
    final normalized = code.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
    if (normalized.contains('K')) {
      return normalized;
    }
    return '${normalized}K';
  }

  Future<void> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasLinkedAssets()) {
      await showDialog(
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
                  AppStrings.cannotDelete.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.financeHasLinkedAssets.tr.replaceAll('{code}', widget.finance?.code ?? ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.5,
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
                      AppStrings.ok.tr,
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
      return;
    }

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
                AppStrings.deleteFinance.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.deleteFinanceConfirmation.tr.replaceAll('{code}', widget.finance?.code ?? ''),
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
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.delete.tr,
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

    if (confirmed == true && widget.finance != null) {
      setState(() {
        _isDeleting = true;
      });

      final financeProvider =
          Provider.of<FinanceProvider>(context, listen: false);
      final success = await financeProvider.deleteFinance(widget.finance!.id);

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.failedToDeleteFinance.tr),
            ),
          );
        }
      }
    }
  }
}
