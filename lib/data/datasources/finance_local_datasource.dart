import 'package:asset_it/core/enums/finance_enums.dart';
import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/data/entities/finance.dart';

abstract class FinanceLocalDatasource {
  Future<List<Finance>> getAllFinances();
  Future<List<Finance>> getFinancesByType(FinanceType type);
  Future<Finance?> getFinanceByCode(String code, {FinanceType? type});
  Future<Finance?> getFinanceById(String id);
  Future<void> insertFinance(Finance finance);
  Future<void> updateFinance(Finance finance);
  Future<void> deleteFinance(String id);
  Future<void> deleteFinancesByType(FinanceType type);
  Future<void> bulkInsertFinances(List<Finance> finances);
  Future<void> updateFinanceValue(String code, double value, {FinanceType? type});
  Future<void> clearAllFinances();
  Future<void> clearFinancesByBaseCurrencyAndType(String baseCurrency, FinanceType type);
  Future<void> clearFinancesByBaseCurrency(String baseCurrency);
  Future<Map<String, double>> getLatestCurrencyRates({String baseCurrency});
  Future<Map<String, double>> getLatestGoldFinances();
}

class FinanceLocalDatasourceImpl implements FinanceLocalDatasource {

  final IDatabaseManager databaseManager;

  FinanceLocalDatasourceImpl({required this.databaseManager});

  @override
  Future<List<Finance>> getAllFinances() async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.financesTable,
      orderBy: 'type, code',
    );
    return maps.map((map) => Finance.fromMap(map)).toList();
  }

  @override
  Future<List<Finance>> getFinancesByType(FinanceType type) async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.financesTable,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'code',
    );
    return maps.map((map) => Finance.fromMap(map)).toList();
  }

  @override
  Future<Finance?> getFinanceByCode(String code, {FinanceType? type}) async {
    String whereClause = 'code = ?';
    List<dynamic> whereArgs = [code];
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.name);
    }
    
    final maps = await databaseManager.query(
      AppLocalStorageKeys.financesTable,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Finance.fromMap(maps.first);
  }

  @override
  Future<Finance?> getFinanceById(String id) async {
    final maps = await databaseManager.query(
      AppLocalStorageKeys.financesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Finance.fromMap(maps.first);
  }

  @override
  Future<void> insertFinance(Finance finance) async {
    await databaseManager.insert(
      AppLocalStorageKeys.financesTable,
      finance.toMap(),
    );
  }

  @override
  Future<void> updateFinance(Finance finance) async {
    await databaseManager.update(
      AppLocalStorageKeys.financesTable,
      finance.toMap(),
      where: 'id = ?',
      whereArgs: [finance.id],
    );
  }

  @override
  Future<void> deleteFinance(String id) async {
    await databaseManager.delete(
      AppLocalStorageKeys.financesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteFinancesByType(FinanceType type) async {
    await databaseManager.delete(
      AppLocalStorageKeys.financesTable,
      where: 'type = ?',
      whereArgs: [type.name],
    );
  }

  @override
  Future<void> bulkInsertFinances(List<Finance> finances) async {
    for (final finance in finances) {
      await databaseManager.insert(
        AppLocalStorageKeys.financesTable,
        finance.toMap(),
      );
    }
  }

  @override
  Future<void> updateFinanceValue(String code, double value, {FinanceType? type}) async {
    String whereClause = 'code = ?';
    List<dynamic> whereArgs = [code];
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.name);
    }
    
    await databaseManager.update(
      AppLocalStorageKeys.financesTable,
      {
        'value': value,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<void> clearAllFinances() async {
    await databaseManager.delete(AppLocalStorageKeys.financesTable);
  }

  @override
  Future<void> clearFinancesByBaseCurrencyAndType(String baseCurrency, FinanceType type) async {
    await databaseManager.delete(
      AppLocalStorageKeys.financesTable,
      where: 'baseCurrency = ? AND type = ?',
      whereArgs: [baseCurrency, type.name],
    );
  }

  @override
  Future<void> clearFinancesByBaseCurrency(String baseCurrency) async {
    await databaseManager.delete(
      AppLocalStorageKeys.financesTable,
      where: 'baseCurrency = ?',
      whereArgs: [baseCurrency],
    );
  }

  @override
  Future<Map<String, double>> getLatestCurrencyRates({String baseCurrency = 'USD'}) async {
    final finances = await getFinancesByType(FinanceType.currency);
    final Map<String, double> rates = {};
    
    for (final finance in finances) {
      rates[finance.code] = finance.value;
    }
    
    return rates;
  }

  @override
  Future<Map<String, double>> getLatestGoldFinances() async {
    final finances = await getFinancesByType(FinanceType.gold);
    final Map<String, double> goldFinances = {};
    
    for (final finance in finances) {
      goldFinances[finance.code] = finance.value;
    }
    
    return goldFinances;
  }
}
