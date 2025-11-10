import 'package:flutter/foundation.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/entities/currency_choice.dart';
import 'package:asset_it/data/datasources/currency_choice_local_datasource.dart';
import 'package:uuid/uuid.dart';

class CurrencyChoiceProvider with ChangeNotifier {
  final CurrencyChoiceLocalDatasource _datasource;
  
  List<CurrencyChoice> _currencyChoices = [];
  CurrencyChoice? _activeCurrencyChoice;
  bool _isLoading = false;
  String? _error;

  List<CurrencyChoice> get currencyChoices => _currencyChoices;
  CurrencyChoice? get activeCurrencyChoice => _activeCurrencyChoice;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCurrencyChoices => _currencyChoices.isNotEmpty;

  CurrencyChoiceProvider(this._datasource) {
    loadCurrencyChoices();
  }

  Future<void> loadCurrencyChoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currencyChoices = await _datasource.getAllCurrencyChoices();
      _activeCurrencyChoice = await _datasource.getActiveCurrencyChoice();
    } catch (e) {
      _error = '${AppStrings.failedToLoadCurrencyChoices.tr}: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CurrencyChoice?> createCurrencyChoice({
    required String baseCurrency,
    required String currencyName,
    required String currencySymbol,
    bool setAsActive = false,
  }) async {
    try {
      final existingChoice = await _datasource.getCurrencyChoiceByCurrency(baseCurrency);
      
      if (existingChoice != null) {
        if (setAsActive) {
          await setActiveCurrencyChoice(existingChoice.id);
        }
        return existingChoice;
      }

      final newChoice = CurrencyChoice(
        id: const Uuid().v4(),
        baseCurrency: baseCurrency,
        currencyName: currencyName,
        currencySymbol: currencySymbol,
        isActive: setAsActive,
        createdDate: DateTime.now(),
        lastAccessedDate: setAsActive ? DateTime.now() : null,
      );

      await _datasource.insertCurrencyChoice(newChoice);

      if (setAsActive) {
        await _datasource.setActiveCurrencyChoice(newChoice.id);
        _activeCurrencyChoice = newChoice;
      }

      await loadCurrencyChoices();
      return newChoice;
    } catch (e) {
      _error = '${AppStrings.failedToCreateCurrencyChoice.tr}: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCurrencyChoice(CurrencyChoice choice) async {
    try {
      await _datasource.updateCurrencyChoice(choice);
      await loadCurrencyChoices();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToUpdateCurrencyChoice.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCurrencyChoice(String id) async {
    try {
      if (_activeCurrencyChoice?.id == id) {
        _error = AppStrings.cannotDeleteActiveCurrency.tr;
        notifyListeners();
        return false;
      }

      await _datasource.deleteCurrencyChoice(id);
      await loadCurrencyChoices();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToDeleteCurrencyChoice.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setActiveCurrencyChoice(String id) async {
    try {
      await _datasource.setActiveCurrencyChoice(id);
      _activeCurrencyChoice = await _datasource.getCurrencyChoiceById(id);
      await loadCurrencyChoices();
      return true;
    } catch (e) {
      _error = '${AppStrings.failedToSetActiveCurrency.tr}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> clearAllCurrencyChoices() async {
    try {
      await _datasource.clearAllCurrencyChoices();
      _currencyChoices = [];
      _activeCurrencyChoice = null;
      notifyListeners();
    } catch (e) {
      _error = '${AppStrings.failedToClearCurrencyChoices.tr}: $e';
      notifyListeners();
    }
  }

  String getActiveCurrencyCode() {
    return _activeCurrencyChoice?.baseCurrency ?? '';
  }

  String getActiveCurrencySymbol() {
    return _activeCurrencyChoice?.currencySymbol ?? '';
  }

  String getActiveCurrencyName() {
    return _activeCurrencyChoice?.currencyName ?? '';
  }
}
