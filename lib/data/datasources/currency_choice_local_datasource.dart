import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/data/entities/currency_choice.dart';

abstract class CurrencyChoiceLocalDatasource {
  Future<List<CurrencyChoice>> getAllCurrencyChoices();
  Future<CurrencyChoice?> getActiveCurrencyChoice();
  Future<CurrencyChoice?> getCurrencyChoiceById(String id);
  Future<CurrencyChoice?> getCurrencyChoiceByCurrency(String baseCurrency);
  Future<void> insertCurrencyChoice(CurrencyChoice choice);
  Future<void> updateCurrencyChoice(CurrencyChoice choice);
  Future<void> deleteCurrencyChoice(String id);
  Future<void> setActiveCurrencyChoice(String id);
  Future<void> clearAllCurrencyChoices();
  Future<bool> hasCurrencyChoices();
}

class CurrencyChoiceLocalDatasourceImpl implements CurrencyChoiceLocalDatasource {

  final IDatabaseManager databaseManager;

  CurrencyChoiceLocalDatasourceImpl({required this.databaseManager});

  @override
  Future<List<CurrencyChoice>> getAllCurrencyChoices() async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.currencyChoicesTable,
      orderBy: 'lastAccessedDate DESC',
    );
    return maps.map((map) => CurrencyChoice.fromMap(map)).toList();
  }

  @override
  Future<CurrencyChoice?> getActiveCurrencyChoice() async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.currencyChoicesTable,
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CurrencyChoice.fromMap(maps.first);
  }

  @override
  Future<CurrencyChoice?> getCurrencyChoiceById(String id) async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.currencyChoicesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CurrencyChoice.fromMap(maps.first);
  }

  @override
  Future<CurrencyChoice?> getCurrencyChoiceByCurrency(String baseCurrency) async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.currencyChoicesTable,
      where: 'baseCurrency = ?',
      whereArgs: [baseCurrency],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CurrencyChoice.fromMap(maps.first);
  }

  @override
  Future<void> insertCurrencyChoice(CurrencyChoice choice) async {
    await databaseManager.insert(
      AppLocalStorageKeys.currencyChoicesTable,
      choice.toMap(),
    );
  }

  @override
  Future<void> updateCurrencyChoice(CurrencyChoice choice) async {
    await databaseManager.update(
      AppLocalStorageKeys.currencyChoicesTable,
      choice.toMap(),
      where: 'id = ?',
      whereArgs: [choice.id],
    );
  }

  @override
  Future<void> deleteCurrencyChoice(String id) async {
    await databaseManager.delete(
      AppLocalStorageKeys.currencyChoicesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> setActiveCurrencyChoice(String id) async {
    await databaseManager.update(
      AppLocalStorageKeys.currencyChoicesTable,
      {'isActive': 0},
      where: 'isActive = ?',
      whereArgs: [1],
    );
    
    await databaseManager.update(
      AppLocalStorageKeys.currencyChoicesTable,
      {
        'isActive': 1,
        'lastAccessedDate': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllCurrencyChoices() async {
    await databaseManager.delete(AppLocalStorageKeys.currencyChoicesTable);
  }

  @override
  Future<bool> hasCurrencyChoices() async {
    final result = await databaseManager.query(
      AppLocalStorageKeys.currencyChoicesTable,
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
