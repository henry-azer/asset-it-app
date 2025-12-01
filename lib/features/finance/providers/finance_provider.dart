import 'package:flutter/foundation.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/entities/finance.dart';
import 'package:asset_it/data/datasources/finance_local_datasource.dart';
import 'package:asset_it/core/enums/finance_enums.dart';
import 'package:uuid/uuid.dart';
import 'package:asset_it/core/services/currency_service.dart';
import 'package:asset_it/data/datasources/market_data_datasource.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceLocalDatasource _datasource;
  final CurrencyChoiceProvider _currencyChoiceProvider;
  
  List<Finance> _finances = [];
  List<Finance> _currencyFinances = [];
  List<Finance> _goldFinances = [];
  List<Finance> _stockFinances = [];
  bool _isLoading = false;
  bool _isFinancesLoaded = false;
  String? _error;
  bool _useManualFinances = false;

  bool _isInitialized = false;

  FinanceProvider(this._datasource, this._currencyChoiceProvider) {
    _initializeFinances();
  }

  Future<void> _initializeFinances() async {
    await loadFinances();
    _isInitialized = true;
  }

  List<Finance> get finances => _finances;

  List<Finance> get currencyFinances => _currencyFinances;

  List<Finance> get goldFinances => _goldFinances;

  List<Finance> get stockFinances => _stockFinances;

  bool get isLoading => _isLoading;

  bool get isFinancesLoaded => _isFinancesLoaded;

  bool get isInitialized => _isInitialized;

  String? get error => _error;

  bool get useManualFinances => _useManualFinances;

  Future<void> loadFinances() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baseCurrency = _currencyChoiceProvider.getActiveCurrencyCode();
      final allFinances = await _datasource.getAllFinances();

      _finances =
          allFinances.where((f) => f.baseCurrency == baseCurrency).toList();
      _currencyFinances =
          _finances.where((f) => f.type == FinanceType.currency).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _goldFinances =
          _finances.where((f) => f.type == FinanceType.gold).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _stockFinances =
          _finances.where((f) => f.type == FinanceType.stock).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _isFinancesLoaded = true;
    } catch (e) {
      _error = '${AppStrings.failedToLoadFinances.tr}: $e';
      _isFinancesLoaded = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFinance(Finance finance) async {
    try {
      List<Finance> sameTypeFinances;
      switch (finance.type) {
        case FinanceType.currency:
          sameTypeFinances = _currencyFinances;
          break;
        case FinanceType.gold:
          sameTypeFinances = _goldFinances;
          break;
        case FinanceType.stock:
          sameTypeFinances = _stockFinances;
          break;
      }
      
      final maxSortOrder = sameTypeFinances.isEmpty
          ? -1
          : sameTypeFinances.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b);
      
      final financeWithSortOrder = finance.copyWith(sortOrder: maxSortOrder + 1);
      await _datasource.insertFinance(financeWithSortOrder);
      await loadFinances();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToAddFinance.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFinance(Finance finance) async {
    try {
      await _datasource.updateFinance(finance);
      await loadFinances();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToUpdateFinance.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFinance(String id) async {
    try {
      await _datasource.deleteFinance(id);
      await loadFinances();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToDeleteFinance.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFinanceValue(String code, double value,
      {FinanceType? type}) async {
    try {
      await _datasource.updateFinanceValue(code, value, type: type);
      await loadFinances();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToUpdateFinanceValue.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Finance? getFinanceByCode(String code, {FinanceType? type}) {
    try {
      final baseCurrency = _currencyChoiceProvider.getActiveCurrencyCode();
      return _finances.firstWhere(
        (f) =>
            f.code == code &&
            f.baseCurrency == baseCurrency &&
            (type == null || f.type == type),
      );
    } catch (e) {
      return null;
    }
  }

  Finance? getFinanceByCodeAndBaseCurrency(String code, String baseCurrency,
      {FinanceType? type}) {
    try {
      return _finances.firstWhere(
        (f) =>
            f.code == code &&
            f.baseCurrency == baseCurrency &&
            (type == null || f.type == type),
      );
    } catch (e) {
      return null;
    }
  }

  double getCurrencyRate(String currencyCode) {
    final baseCurrency = _currencyChoiceProvider.getActiveCurrencyCode();
    final finance = getFinanceByCodeAndBaseCurrency(currencyCode, baseCurrency,
        type: FinanceType.currency);
    if (finance == null) return 1.0;
    return finance.value;
  }

  double? getGoldFinance(String goldType) {
    if (!_isFinancesLoaded) {
      return null;
    }

    final baseCurrency = _currencyChoiceProvider.getActiveCurrencyCode();

    Finance? finance = getFinanceByCodeAndBaseCurrency(goldType, baseCurrency,
        type: FinanceType.gold);

    if (finance == null) {
      final normalizedType = goldType.replaceAll(RegExp(r'[^0-9]'), '') + 'K';
      final normalizedCode = 'GOLD${normalizedType.toUpperCase()}';

      try {
        finance = _goldFinances.firstWhere(
          (f) =>
              f.code.toUpperCase() == normalizedCode &&
              f.baseCurrency == baseCurrency,
        );
      } catch (e) {
        if (goldType.contains(RegExp(r'\d+'))) {
          final karatNumber = RegExp(r'\d+').firstMatch(goldType)?.group(0);
          if (karatNumber != null) {
            try {
              finance = _goldFinances.firstWhere(
                (f) =>
                    f.code.contains(karatNumber) && f.baseCurrency == baseCurrency,
              );
            } catch (e) {
              finance = null;
            }
          }
        }
      }
    }

    return finance?.value;
  }

  Future<void> fetchAndUpdateFinances() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final baseCurrency = _currencyChoiceProvider.getActiveCurrencyCode();

      final currencyRates =
          await MarketDataDatasource.fetchCurrencyRates(baseCurrency);

      if (currencyRates.isEmpty) {
        throw Exception(AppStrings.noCurrencyDataReceived.tr);
      }

      final existingCurrencies = _currencyFinances;
      final financesToUpdate = <Finance>[];
      final financesToInsert = <Finance>[];

      currencyRates.forEach((code, rate) {
        final existingFinance = existingCurrencies.firstWhere(
          (f) => f.code == code && f.baseCurrency == baseCurrency,
          orElse: () => Finance(
            id: '',
            type: FinanceType.currency,
            code: '',
            name: '',
            value: 0,
            baseCurrency: '',
            lastUpdated: DateTime.now(),
          ),
        );

        if (existingFinance.id.isNotEmpty) {
          financesToUpdate.add(Finance(
            id: existingFinance.id,
            type: FinanceType.currency,
            code: code,
            name: CurrencyService.getCurrencyName(code),
            value: rate,
            baseCurrency: baseCurrency,
            lastUpdated: DateTime.now(),
          ));
        } else {
          financesToInsert.add(Finance(
            id: const Uuid().v4(),
            type: FinanceType.currency,
            code: code,
            name: CurrencyService.getCurrencyName(code),
            value: rate,
            baseCurrency: baseCurrency,
            lastUpdated: DateTime.now(),
          ));
        }
      });

      for (final finance in financesToUpdate) {
        await _datasource.updateFinance(finance);
      }

      if (financesToInsert.isNotEmpty) {
        await _datasource.bulkInsertFinances(financesToInsert);
      }

      await loadFinances();
    } catch (e) {
      print('${AppStrings.failedToFetchCurrencies.tr}: $e');
      _error = '${AppStrings.failedToFetchCurrencies.tr}: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void setUseManualFinances(bool value) {
    _useManualFinances = value;
    notifyListeners();
  }

  Future<void> clearAllFinances() async {
    try {
      await _datasource.clearAllFinances();
      _finances = [];
      _currencyFinances = [];
      _goldFinances = [];
      _stockFinances = [];
      notifyListeners();
    } catch (e) {
      _error = '${AppStrings.failedToClearFinances.tr}: $e';
      notifyListeners();
    }
  }

  Future<void> reorderFinances(FinanceType type, int oldIndex, int newIndex) async {
    List<Finance> financeList;
    switch (type) {
      case FinanceType.currency:
        financeList = _currencyFinances;
        break;
      case FinanceType.gold:
        financeList = _goldFinances;
        break;
      case FinanceType.stock:
        financeList = _stockFinances;
        break;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex < 0 || oldIndex >= financeList.length) return;
    if (newIndex < 0 || newIndex >= financeList.length) return;
    if (oldIndex == newIndex) return;

    final finance = financeList.removeAt(oldIndex);
    financeList.insert(newIndex, finance);
    notifyListeners();

    try {
      for (int i = 0; i < financeList.length; i++) {
        final updatedFinance = financeList[i].copyWith(sortOrder: i);
        financeList[i] = updatedFinance;
        await _datasource.updateFinance(updatedFinance);
      }
    } catch (e) {
      _error = 'Failed to save reorder: $e';
      notifyListeners();
      await loadFinances();
    }
  }
}
