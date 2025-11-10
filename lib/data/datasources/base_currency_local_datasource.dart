import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/data/entities/base_currency.dart';

abstract class BaseCurrencyLocalDatasource {
  Future<List<BaseCurrency>> getAllBaseCurrencies();
  Future<List<BaseCurrency>> getCustomCurrencies();
  Future<List<BaseCurrency>> getCachedCurrencies();
  Future<BaseCurrency?> getBaseCurrencyByCode(String code);
  Future<void> insertBaseCurrency(BaseCurrency currency);
  Future<void> insertBaseCurrencies(List<BaseCurrency> currencies);
  Future<void> updateBaseCurrency(BaseCurrency currency);
  Future<void> deleteBaseCurrency(String code);
  Future<void> clearCachedCurrencies();
  Future<void> clearAllBaseCurrencies();
  Future<bool> hasCachedCurrencies();
}

class BaseCurrencyLocalDatasourceImpl implements BaseCurrencyLocalDatasource {
  final IDatabaseManager databaseManager;

  BaseCurrencyLocalDatasourceImpl({required this.databaseManager});

  @override
  Future<List<BaseCurrency>> getAllBaseCurrencies() async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.baseCurrenciesTable,
      orderBy: 'code ASC',
    );
    return maps.map((map) => BaseCurrency.fromMap(map)).toList();
  }

  @override
  Future<List<BaseCurrency>> getCustomCurrencies() async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.baseCurrenciesTable,
      where: 'isCustom = ?',
      whereArgs: [1],
      orderBy: 'code ASC',
    );
    return maps.map((map) => BaseCurrency.fromMap(map)).toList();
  }

  @override
  Future<List<BaseCurrency>> getCachedCurrencies() async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.baseCurrenciesTable,
      where: 'isCustom = ?',
      whereArgs: [0],
      orderBy: 'code ASC',
    );
    return maps.map((map) => BaseCurrency.fromMap(map)).toList();
  }

  @override
  Future<BaseCurrency?> getBaseCurrencyByCode(String code) async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.baseCurrenciesTable,
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BaseCurrency.fromMap(maps.first);
  }

  @override
  Future<void> insertBaseCurrency(BaseCurrency currency) async {
    await databaseManager.insert(
      AppLocalStorageKeys.baseCurrenciesTable,
      currency.toMap(),
    );
  }

  @override
  Future<void> insertBaseCurrencies(List<BaseCurrency> currencies) async {
    for (final currency in currencies) {
      await databaseManager.insert(
        AppLocalStorageKeys.baseCurrenciesTable,
        currency.toMap(),
      );
    }
  }

  @override
  Future<void> updateBaseCurrency(BaseCurrency currency) async {
    await databaseManager.update(
      AppLocalStorageKeys.baseCurrenciesTable,
      currency.toMap(),
      where: 'code = ?',
      whereArgs: [currency.code],
    );
  }

  @override
  Future<void> deleteBaseCurrency(String code) async {
    await databaseManager.delete(
      AppLocalStorageKeys.baseCurrenciesTable,
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  @override
  Future<void> clearCachedCurrencies() async {
    await databaseManager.delete(
      AppLocalStorageKeys.baseCurrenciesTable,
      where: 'isCustom = ?',
      whereArgs: [0],
    );
  }

  @override
  Future<void> clearAllBaseCurrencies() async {
    await databaseManager.delete(AppLocalStorageKeys.baseCurrenciesTable);
  }

  @override
  Future<bool> hasCachedCurrencies() async {
    final result = await databaseManager.query(
      AppLocalStorageKeys.baseCurrenciesTable,
      where: 'isCustom = ?',
      whereArgs: [0],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
