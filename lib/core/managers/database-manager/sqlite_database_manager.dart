import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteDatabaseManager extends IDatabaseManager {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    final manager = SQLiteDatabaseManager();
    await manager.init();
    return _database!;
  }

  @override
  Future<void> init() async {
    if (_database != null) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppLocalStorageKeys.databaseName);

    _database = await openDatabase(
      path,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE ${AppLocalStorageKeys.currencyChoicesTable}(
        id TEXT PRIMARY KEY,
        baseCurrency TEXT NOT NULL UNIQUE,
        currencyName TEXT NOT NULL,
        currencySymbol TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0,
        createdDate TEXT NOT NULL,
        lastAccessedDate TEXT
      )''',
    );

    await db.execute(
      '''CREATE TABLE ${AppLocalStorageKeys.assetsTable}(
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initialValue REAL NOT NULL,
        dateAdded TEXT NOT NULL,
        notes TEXT,
        details TEXT,
        baseCurrency TEXT,
        sortOrder INTEGER DEFAULT 0,
        calculatedCurrentValue REAL,
        calculatedPurchaseValue REAL,
        lastCalculated TEXT,
        FOREIGN KEY (profileId) REFERENCES ${AppLocalStorageKeys.currencyChoicesTable}(id) ON DELETE CASCADE
      )''',
    );

    await db.execute(
      '''CREATE TABLE asset_type_ordering(
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        assetType TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        UNIQUE(profileId, assetType),
        FOREIGN KEY (profileId) REFERENCES ${AppLocalStorageKeys.currencyChoicesTable}(id) ON DELETE CASCADE
      )''',
    );

    await db.execute(
      '''CREATE TABLE ${AppLocalStorageKeys.usersTable}(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        createdDate TEXT NOT NULL
      )''',
    );

    await db.execute(
      '''CREATE TABLE ${AppLocalStorageKeys.financesTable}(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT,
        value REAL NOT NULL,
        baseCurrency TEXT,
        lastUpdated TEXT NOT NULL,
        metadata TEXT,
        UNIQUE(type, code)
      )''',
    );

    await db.execute(
      '''CREATE TABLE ${AppLocalStorageKeys.baseCurrenciesTable}(
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        isCustom INTEGER NOT NULL DEFAULT 0,
        lastUpdated TEXT NOT NULL
      )''',
    );

    await db.execute(
      '''CREATE TABLE ${AppLocalStorageKeys.salariesTable}(
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        name TEXT,
        amount REAL NOT NULL,
        incomes TEXT,
        spendings TEXT NOT NULL,
        dateAdded TEXT NOT NULL,
        notes TEXT,
        sortOrder INTEGER DEFAULT 0,
        FOREIGN KEY (profileId) REFERENCES ${AppLocalStorageKeys.currencyChoicesTable}(id) ON DELETE CASCADE
      )''',
    );

    await db.execute(
      'CREATE INDEX idx_currency_choices_active ON ${AppLocalStorageKeys.currencyChoicesTable}(isActive)',
    );

    await db.execute(
      'CREATE INDEX idx_assets_profile ON ${AppLocalStorageKeys.assetsTable}(profileId)',
    );

    await db.execute(
      'CREATE INDEX idx_assets_type ON ${AppLocalStorageKeys.assetsTable}(type)',
    );

    await db.execute(
      'CREATE INDEX idx_finances_type_code ON ${AppLocalStorageKeys.financesTable}(type, code)',
    );

    await db.execute(
      'CREATE INDEX idx_base_currencies_custom ON ${AppLocalStorageKeys.baseCurrenciesTable}(isCustom)',
    );

    await db.execute(
      'CREATE INDEX idx_assets_sort_order ON ${AppLocalStorageKeys.assetsTable}(sortOrder)',
    );

    await db.execute(
      'CREATE INDEX idx_asset_type_ordering_profile ON asset_type_ordering(profileId)',
    );

    await db.execute(
      'CREATE INDEX idx_salaries_profile ON ${AppLocalStorageKeys.salariesTable}(profileId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    await init();
    return await _database!.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    await init();
    final result = await _database!.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    await init();
    return await _database!.update(table, data, where: where, whereArgs: whereArgs, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    await init();
    return await _database!.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
