import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asset_it/core/enums/currency_enums.dart';
import 'package:asset_it/data/datasources/base_currency_local_datasource.dart';
import 'package:asset_it/data/entities/base_currency.dart';

class CurrencyService {
  final BaseCurrencyLocalDatasource _datasource;
  static const String _apiBaseUrl = 'https://api.exchangerate-api.com/v4/latest';

  CurrencyService(this._datasource);

  static String getCurrencySymbol(String code) {
    return Currency.getSymbol(code);
  }

  static String getCurrencyName(String code) {
    return Currency.getName(code);
  }

  static Future<Map<String, double>?> fetchExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$baseCurrency'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> fetchAvailableCurrencies() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/USD'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        final currencies = rates.keys.toList();
        currencies.sort();
        
        await _cacheCurrenciesFromAPI(currencies);
        
        return currencies;
      }
      
      final cachedCurrencies = await _getCachedCurrencyCodes();
      return cachedCurrencies.isNotEmpty ? cachedCurrencies : ['USD'];
    } catch (e) {
      final cachedCurrencies = await _getCachedCurrencyCodes();
      return cachedCurrencies.isNotEmpty ? cachedCurrencies : ['USD'];
    }
  }

  Future<void> _cacheCurrenciesFromAPI(List<String> currencyCodes) async {
    try {
      final hasCached = await _datasource.hasCachedCurrencies();
      
      if (!hasCached) {
        final currencies = currencyCodes.map((code) {
          return BaseCurrency(
            code: code,
            name: getCurrencyName(code),
            symbol: getCurrencySymbol(code),
            isCustom: false,
            lastUpdated: DateTime.now(),
          );
        }).toList();
        
        await _datasource.insertBaseCurrencies(currencies);
      }
    } catch (e) {
    }
  }

  Future<List<String>> _getCachedCurrencyCodes() async {
    try {
      final currencies = await _datasource.getAllBaseCurrencies();
      return currencies.map((c) => c.code).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getAvailableCurrenciesWithCustom() async {
    try {
      final allCurrencies = await _datasource.getAllBaseCurrencies();
      final codes = allCurrencies.map((c) => c.code).toList();
      codes.sort();
      return codes;
    } catch (e) {
      return await fetchAvailableCurrencies();
    }
  }

  Future<List<String>> fetchAndCacheCurrencies() async {
    try {
      final existingCurrencies = await _datasource.getAllBaseCurrencies();
      final customCurrencies = existingCurrencies.where((c) => c.isCustom).toList();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/USD'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        final currencies = rates.keys.toList();
        currencies.sort();
        
        final currencyEntities = currencies.map((code) {
          return BaseCurrency(
            code: code,
            name: getCurrencyName(code),
            symbol: getCurrencySymbol(code),
            isCustom: false,
            lastUpdated: DateTime.now(),
          );
        }).toList();
        
        await _datasource.clearAllBaseCurrencies();
        await _datasource.insertBaseCurrencies(currencyEntities);
        
        if (customCurrencies.isNotEmpty) {
          await _datasource.insertBaseCurrencies(customCurrencies);
        }
        
        final customCodes = customCurrencies.map((c) => c.code).toList();
        final allCodes = [...currencies, ...customCodes];
        allCodes.sort();
        
        return allCodes;
      }
      
      final cachedCurrencies = await _getCachedCurrencyCodes();
      return cachedCurrencies.isNotEmpty ? cachedCurrencies : ['USD'];
    } catch (e) {
      final cachedCurrencies = await _getCachedCurrencyCodes();
      return cachedCurrencies.isNotEmpty ? cachedCurrencies : ['USD'];
    }
  }

  Future<void> addCustomCurrency({
    required String code,
    required String name,
    required String symbol,
  }) async {
    final existing = await _datasource.getBaseCurrencyByCode(code);
    if (existing != null) return;

    final currency = BaseCurrency(
      code: code.toUpperCase(),
      name: name,
      symbol: symbol,
      isCustom: true,
      lastUpdated: DateTime.now(),
    );

    await _datasource.insertBaseCurrency(currency);
  }

  Future<bool> isCustomCurrency(String code) async {
    final currency = await _datasource.getBaseCurrencyByCode(code);
    return currency?.isCustom ?? false;
  }

  static List<Map<String, String>> getDefaultCurrencies() {
    return [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    ];
  }
}
