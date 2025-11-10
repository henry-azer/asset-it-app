import 'package:flutter/foundation.dart';
import 'package:asset_it/core/managers/storage-manager/i_storage_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/injection_container.dart';

class CurrencyProvider extends ChangeNotifier {
  final IStorageManager _storageManager = sl<IStorageManager>();

  String _currentCurrency = '';
  Map<String, double> _exchangeRates = {};
  Map<String, double> _goldPrices = {};
  Map<String, double> _stockPrices = {};
  bool _useManualPrices = true;

  String get currentCurrency => _currentCurrency;

  Map<String, double> get exchangeRates => _exchangeRates;

  Map<String, double> get goldPrices => _goldPrices;

  Map<String, double> get stockPrices => _stockPrices;

  bool get useManualPrices => _useManualPrices;

  CurrencyProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _currentCurrency = await _storageManager.getString(
          AppLocalStorageKeys.currentCurrency,
        ) ??
        '';

    _useManualPrices = await _storageManager.getBool(
          AppLocalStorageKeys.useManualPrices,
        ) ??
        true;

    await _loadExchangeRates();
    await _loadGoldPrices();
    await _loadStockPrices();

    notifyListeners();
  }

  Future<void> _loadExchangeRates() async {
    final ratesJson = await _storageManager.getString(
      AppLocalStorageKeys.manualExchangeRates,
    );
    if (ratesJson != null && ratesJson.isNotEmpty) {
      final decoded = Map<String, dynamic>.from(
        Map<String, dynamic>.from(
          _parseJson(ratesJson),
        ),
      );
      _exchangeRates =
          decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
  }

  Future<void> _loadGoldPrices() async {
    final pricesJson = await _storageManager.getString(
      AppLocalStorageKeys.manualGoldPrices,
    );
    if (pricesJson != null && pricesJson.isNotEmpty) {
      final decoded = Map<String, dynamic>.from(
        _parseJson(pricesJson),
      );
      _goldPrices = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
  }

  Future<void> _loadStockPrices() async {
    final pricesJson = await _storageManager.getString(
      AppLocalStorageKeys.manualStockPrices,
    );
    if (pricesJson != null && pricesJson.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(
          _parseJson(pricesJson),
        );
        _stockPrices =
            decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (e) {
        _stockPrices = {};
      }
    } else {
      _stockPrices = {};
    }
  }

  Map<String, dynamic> _parseJson(String json) {
    return {};
  }

  Future<void> setCurrency(String currency) async {
    _currentCurrency = currency;
    await _storageManager.setString(
      AppLocalStorageKeys.currentCurrency,
      currency,
    );
    notifyListeners();
  }

  Future<void> setExchangeRate(String pair, double rate) async {
    _exchangeRates[pair] = rate;
    await _saveExchangeRates();
    notifyListeners();
  }

  Future<void> setGoldPrice(String karat, double price) async {
    _goldPrices[karat] = price;
    await _saveGoldPrices();
    notifyListeners();
  }

  Future<void> setStockPrice(String symbol, double price) async {
    _stockPrices[symbol] = price;
    await _saveStockPrices();
    notifyListeners();
  }

  Future<void> _saveExchangeRates() async {
    await _storageManager.setString(
      AppLocalStorageKeys.manualExchangeRates,
      _exchangeRates.toString(),
    );
  }

  Future<void> _saveGoldPrices() async {
    await _storageManager.setString(
      AppLocalStorageKeys.manualGoldPrices,
      _goldPrices.toString(),
    );
  }

  Future<void> _saveStockPrices() async {
    await _storageManager.setString(
      AppLocalStorageKeys.manualStockPrices,
      _stockPrices.toString(),
    );
  }

  Future<void> toggleManualPrices(bool value) async {
    _useManualPrices = value;
    await _storageManager.setBool(
      AppLocalStorageKeys.useManualPrices,
      value,
    );
    notifyListeners();
  }
}
