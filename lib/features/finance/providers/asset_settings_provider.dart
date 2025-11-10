import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AssetSettingsProvider extends ChangeNotifier {
  static const String _currenciesKey = 'asset_currencies';
  static const String _goldKaratsKey = 'gold_karats';
  static const String _stocksKey = 'stocks';
  static const String _baseCurrencyKey = 'base_currency';

  String _baseCurrency = '';
  Map<String, double> _currencyRates = {};

  Map<String, double> _goldKaratPrices = {};

  Map<String, Map<String, dynamic>> _stocks = {};

  String get baseCurrency => _baseCurrency;

  Map<String, double> get currencyRates => Map.unmodifiable(_currencyRates);

  Map<String, double> get goldKaratPrices => Map.unmodifiable(_goldKaratPrices);

  Map<String, Map<String, dynamic>> get stocks => Map.unmodifiable(_stocks);

  AssetSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _baseCurrency = prefs.getString(_baseCurrencyKey) ?? '';

    final currenciesJson = prefs.getString(_currenciesKey);
    if (currenciesJson != null) {
      _currencyRates = Map<String, double>.from(json.decode(currenciesJson));
    }

    final goldJson = prefs.getString(_goldKaratsKey);
    if (goldJson != null) {
      _goldKaratPrices = Map<String, double>.from(json.decode(goldJson));
    }

    final stocksJson = prefs.getString(_stocksKey);
    if (stocksJson != null) {
      _stocks = Map<String, Map<String, dynamic>>.from(json
          .decode(stocksJson)
          .map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value))));
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseCurrencyKey, _baseCurrency);
    await prefs.setString(_currenciesKey, json.encode(_currencyRates));
    await prefs.setString(_goldKaratsKey, json.encode(_goldKaratPrices));
    await prefs.setString(_stocksKey, json.encode(_stocks));
  }

  void setBaseCurrency(String currency) {
    if (_currencyRates.containsKey(currency)) {
      _baseCurrency = currency;
      _saveSettings();
      notifyListeners();
    }
  }

  void updateCurrencyRate(String currency, double rate) {
    if (rate > 0) {
      _currencyRates[currency] = rate;
      _saveSettings();
      notifyListeners();
    }
  }

  void addCurrency(String code, double rate) {
    if (!_currencyRates.containsKey(code) && rate > 0) {
      _currencyRates[code] = rate;
      _saveSettings();
      notifyListeners();
    }
  }

  void removeCurrency(String code) {
    if (code != _baseCurrency && _currencyRates.containsKey(code)) {
      _currencyRates.remove(code);
      _saveSettings();
      notifyListeners();
    }
  }

  void updateGoldKaratPrice(String karat, double pricePerGram) {
    if (pricePerGram > 0) {
      _goldKaratPrices[karat] = pricePerGram;
      _saveSettings();
      notifyListeners();
    }
  }

  void addStock(String symbol, String name, double price, String currency) {
    if (!_stocks.containsKey(symbol) && price > 0) {
      _stocks[symbol] = {
        'name': name,
        'price': price,
        'currency': currency,
      };
      _saveSettings();
      notifyListeners();
    }
  }

  void updateStock(String symbol, double price) {
    if (_stocks.containsKey(symbol) && price > 0) {
      _stocks[symbol]!['price'] = price;
      _saveSettings();
      notifyListeners();
    }
  }

  void removeStock(String symbol) {
    if (_stocks.containsKey(symbol)) {
      _stocks.remove(symbol);
      _saveSettings();
      notifyListeners();
    }
  }

  double convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = _currencyRates[fromCurrency] ?? 1.0;
    final toRate = _currencyRates[toCurrency] ?? 1.0;

    final usdAmount = amount / fromRate;

    return usdAmount * toRate;
  }

  double calculateAssetCurrentValue(
      String type, Map<String, dynamic> details, double initialValue) {
    switch (type) {
      case 'gold':
        final karat = details['karat'] ?? '24K';
        final grams = (details['grams'] ?? 0.0).toDouble();
        final pricePerGram = _goldKaratPrices[karat] ?? 65.50;
        return grams * pricePerGram;

      case 'stock':
        final symbol = details['symbol'];
        final shares = (details['shares'] ?? 0.0).toDouble();
        if (symbol != null && _stocks.containsKey(symbol)) {
          final stockPrice = _stocks[symbol]!['price'] ?? 0.0;
          return shares * stockPrice;
        }
        return initialValue;

      case 'currency':
        final fromCurrency = details['currency'] ?? 'USD';
        final amount = initialValue;
        return convertCurrency(amount, fromCurrency, _baseCurrency);

      default:
        return initialValue;
    }
  }
}
