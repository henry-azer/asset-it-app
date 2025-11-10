import 'dart:convert';
import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/data/entities/salary.dart';

abstract class SalaryLocalDataSource {
  Future<List<Salary>> getSalaries(String profileId);
  Future<Salary?> getSalaryById(String id);
  Future<void> saveSalary(Salary salary, String profileId);
  Future<void> deleteSalary(String id);
  Future<void> clearSalaries(String profileId);
}

class SalaryLocalDataSourceImpl implements SalaryLocalDataSource {
  final IDatabaseManager databaseManager;

  SalaryLocalDataSourceImpl({required this.databaseManager});

  @override
  Future<List<Salary>> getSalaries(String profileId) async {
    final results = await databaseManager.query(
      AppLocalStorageKeys.salariesTable,
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'dateAdded DESC',
    );
    
    return results.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (modifiedMap['spendings'] != null && modifiedMap['spendings'] is String) {
        modifiedMap['spendings'] = json.decode(modifiedMap['spendings']);
      }
      return Salary.fromMap(modifiedMap);
    }).toList();
  }

  @override
  Future<Salary?> getSalaryById(String id) async {
    final results = await databaseManager.query(
      AppLocalStorageKeys.salariesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    final map = Map<String, dynamic>.from(results.first);
    if (map['spendings'] != null && map['spendings'] is String) {
      map['spendings'] = json.decode(map['spendings']);
    }
    return Salary.fromMap(map);
  }

  @override
  Future<void> saveSalary(Salary salary, String profileId) async {
    final existing = await databaseManager.query(
      AppLocalStorageKeys.salariesTable,
      where: 'id = ?',
      whereArgs: [salary.id],
    );
    
    final map = salary.toMap();
    map['profileId'] = profileId;
    if (map['spendings'] != null) {
      map['spendings'] = json.encode(map['spendings']);
    }
    
    if (existing.isEmpty) {
      await databaseManager.insert(
        AppLocalStorageKeys.salariesTable,
        map,
      );
    } else {
      await databaseManager.update(
        AppLocalStorageKeys.salariesTable,
        map,
        where: 'id = ?',
        whereArgs: [salary.id],
      );
    }
  }

  @override
  Future<void> deleteSalary(String id) async {
    await databaseManager.delete(
      AppLocalStorageKeys.salariesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearSalaries(String profileId) async {
    await databaseManager.delete(
      AppLocalStorageKeys.salariesTable,
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
  }
}
