import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/data/entities/finance.dart';
import 'package:asset_it/data/entities/currency_choice.dart';
import 'package:asset_it/data/entities/user.dart';
import 'package:asset_it/data/entities/base_currency.dart';
import 'package:asset_it/core/managers/database-manager/sqlite_database_manager.dart';
import 'package:asset_it/core/services/encryption_service.dart';
import 'package:sqflite/sqflite.dart';

class BackupInfo {
  final String appName;
  final String version;
  final DateTime exportDate;
  final int assetCount;
  final int financeCount;
  final int currencyChoiceCount;
  final int baseCurrencyCount;
  final int userCount;
  final int salaryCount;
  final String deviceId;

  BackupInfo({
    required this.appName,
    required this.version,
    required this.exportDate,
    required this.assetCount,
    required this.financeCount,
    required this.currencyChoiceCount,
    required this.baseCurrencyCount,
    required this.userCount,
    required this.salaryCount,
    required this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'version': version,
      'export_date': exportDate.toIso8601String(),
      'asset_count': assetCount,
      'finance_count': financeCount,
      'currency_choice_count': currencyChoiceCount,
      'base_currency_count': baseCurrencyCount,
      'user_count': userCount,
      'salary_count': salaryCount,
      'device_id': deviceId,
    };
  }

  factory BackupInfo.fromMap(Map<String, dynamic> map) {
    return BackupInfo(
      appName: map['app_name'] ?? '',
      version: map['version'] ?? '',
      exportDate: DateTime.parse(map['export_date']),
      assetCount: map['asset_count'] ?? 0,
      financeCount: map['finance_count'] ?? 0,
      currencyChoiceCount: map['currency_choice_count'] ?? 0,
      baseCurrencyCount: map['base_currency_count'] ?? 0,
      userCount: map['user_count'] ?? 0,
      salaryCount: map['salary_count'] ?? 0,
      deviceId: map['device_id'] ?? 'unknown',
    );
  }

  String get formattedExportDate {
    final now = DateTime.now();
    final difference = now.difference(exportDate);

    if (difference.inDays == 0) {
      return AppStrings.today.tr;
    } else if (difference.inDays == 1) {
      return AppStrings.yesterday.tr;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${AppStrings.daysAgo.tr}';
    } else {
      return '${exportDate.day}/${exportDate.month}/${exportDate.year}';
    }
  }

  String get timeSinceExport {
    final now = DateTime.now();
    final difference = now.difference(exportDate);

    if (difference.inHours < 24) {
      return '${difference.inHours} ${AppStrings.hoursAgo.tr}';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${AppStrings.daysAgo.tr}';
    } else {
      return '${(difference.inDays / 30).floor()} ${AppStrings.monthsAgo.tr}';
    }
  }

  BackupInfo copyWith({
    String? appName,
    String? version,
    DateTime? exportDate,
    int? assetCount,
    int? financeCount,
    int? currencyChoiceCount,
    int? baseCurrencyCount,
    int? userCount,
    int? salaryCount,
    String? deviceId,
  }) {
    return BackupInfo(
      appName: appName ?? this.appName,
      version: version ?? this.version,
      exportDate: exportDate ?? this.exportDate,
      assetCount: assetCount ?? this.assetCount,
      financeCount: financeCount ?? this.financeCount,
      currencyChoiceCount: currencyChoiceCount ?? this.currencyChoiceCount,
      baseCurrencyCount: baseCurrencyCount ?? this.baseCurrencyCount,
      userCount: userCount ?? this.userCount,
      salaryCount: salaryCount ?? this.salaryCount,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class BackupResult {
  final bool success;
  final String? message;
  final String? filePath;

  BackupResult({
    required this.success,
    this.message,
    this.filePath,
  });
}

class ImportResult {
  final bool success;
  final String? error;
  final List<Asset>? assets;
  final List<Finance>? finances;
  final List<CurrencyChoice>? currencyChoices;
  final List<BaseCurrency>? baseCurrencies;
  final List<User>? users;
  final BackupInfo? backupInfo;

  ImportResult({
    required this.success,
    this.error,
    this.assets,
    this.finances,
    this.currencyChoices,
    this.baseCurrencies,
    this.users,
    this.backupInfo,
  });
}

class LocalBackupProvider with ChangeNotifier {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isPreparingData = false;
  String? _lastBackupPath;
  DateTime? _lastBackupDate;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  bool get isPreparingData => _isPreparingData;
  bool get isProcessing => _isExporting || _isImporting || _isPreparingData;
  String? get lastBackupPath => _lastBackupPath;
  DateTime? get lastBackupDate => _lastBackupDate;

  static Future<Uint8List> _encryptInIsolate(String jsonString) async {
    return compute(_encryptData, jsonString);
  }

  static Uint8List _encryptData(String jsonString) {
    return EncryptionService.encrypt(jsonString);
  }

  static Future<String> _decryptInIsolate(Uint8List encryptedBytes) async {
    return compute(_decryptData, encryptedBytes);
  }

  static String _decryptData(Uint8List encryptedBytes) {
    return EncryptionService.decrypt(encryptedBytes);
  }

  Future<BackupResult> exportToFile() async {
    _isPreparingData = true;
    notifyListeners();

    try {
      final db = await SQLiteDatabaseManager.database;
      
      final results = await Future.wait([
        db.query('assets'),
        db.query('finances'),
        db.query('currency_choices'),
        db.query('base_currencies'),
        db.query('users'),
        db.query('asset_type_ordering'),
        db.query('salaries'),
        PackageInfo.fromPlatform(),
      ]);
      
      final assetMaps = results[0] as List<Map<String, dynamic>>;
      final financeMaps = results[1] as List<Map<String, dynamic>>;
      final currencyChoiceMaps = results[2] as List<Map<String, dynamic>>;
      final baseCurrencyMaps = results[3] as List<Map<String, dynamic>>;
      final userMaps = results[4] as List<Map<String, dynamic>>;
      final assetTypeOrderingMaps = results[5] as List<Map<String, dynamic>>;
      final salaryMaps = results[6] as List<Map<String, dynamic>>;
      final packageInfo = results[7] as PackageInfo;
      
      final processedAssetMaps = <Map<String, dynamic>>[];
      for (var map in assetMaps) {
        final modifiedMap = Map<String, dynamic>.from(map);
        if (modifiedMap['details'] != null && modifiedMap['details'] is String) {
          try {
            modifiedMap['details'] = jsonDecode(modifiedMap['details']);
          } catch (e) {
            modifiedMap['details'] = {};
          }
        }
        processedAssetMaps.add(modifiedMap);
      }
      
      final backupInfo = BackupInfo(
        appName: 'Asset It',
        version: packageInfo.version,
        exportDate: DateTime.now(),
        assetCount: assetMaps.length,
        financeCount: financeMaps.length,
        currencyChoiceCount: currencyChoiceMaps.length,
        baseCurrencyCount: baseCurrencyMaps.length,
        userCount: userMaps.length,
        salaryCount: salaryMaps.length,
        deviceId: 'local_device',
      );

      final backupData = {
        'backup_info': backupInfo.toMap(),
        'assets': processedAssetMaps,
        'finances': financeMaps,
        'currency_choices': currencyChoiceMaps,
        'base_currencies': baseCurrencyMaps,
        'users': userMaps,
        'asset_type_ordering': assetTypeOrderingMaps,
        'salaries': salaryMaps,
      };

      final jsonString = jsonEncode(backupData);
      
      _isPreparingData = false;
      _isExporting = true;
      notifyListeners();
      
      final encryptedBytes = await _encryptInIsolate(jsonString);

      _isExporting = false;
      notifyListeners();

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'asset_it_backup_$timestamp.aes';

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: fileName,
        bytes: encryptedBytes,
      );

      if (outputPath == null) {
        return BackupResult(
          success: false,
          message: AppStrings.exportCancelled.tr,
        );
      }

      String? filePath = outputPath;
      if (Platform.isAndroid || Platform.isIOS) {
        filePath = outputPath;
      } else {
        if (!outputPath.endsWith('.aes')) {
          outputPath = '$outputPath.aes';
        }
        final file = File(outputPath);
        await file.writeAsBytes(encryptedBytes);
        filePath = file.path;
      }

      _lastBackupPath = filePath;
      _lastBackupDate = DateTime.now();
      notifyListeners();

      return BackupResult(
        success: true,
        message: AppStrings.backupSavedSuccessfully.tr,
        filePath: filePath,
      );
    } catch (e) {
      _isPreparingData = false;
      _isExporting = false;
      notifyListeners();
      
      return BackupResult(
        success: false,
        message: '${AppStrings.exportFailedError.tr}: ${e.toString()}',
      );
    }
  }

  Future<BackupResult> shareBackup() async {
    _isPreparingData = true;
    notifyListeners();

    try {
      final db = await SQLiteDatabaseManager.database;
      
      final results = await Future.wait([
        db.query('assets'),
        db.query('finances'),
        db.query('currency_choices'),
        db.query('base_currencies'),
        db.query('users'),
        db.query('asset_type_ordering'),
        db.query('salaries'),
        PackageInfo.fromPlatform(),
      ]);
      
      final assetMaps = results[0] as List<Map<String, dynamic>>;
      final financeMaps = results[1] as List<Map<String, dynamic>>;
      final currencyChoiceMaps = results[2] as List<Map<String, dynamic>>;
      final baseCurrencyMaps = results[3] as List<Map<String, dynamic>>;
      final userMaps = results[4] as List<Map<String, dynamic>>;
      final assetTypeOrderingMaps = results[5] as List<Map<String, dynamic>>;
      final salaryMaps = results[6] as List<Map<String, dynamic>>;
      final packageInfo = results[7] as PackageInfo;
      
      final processedAssetMaps = <Map<String, dynamic>>[];
      for (var map in assetMaps) {
        final modifiedMap = Map<String, dynamic>.from(map);
        if (modifiedMap['details'] != null && modifiedMap['details'] is String) {
          try {
            modifiedMap['details'] = jsonDecode(modifiedMap['details']);
          } catch (e) {
            modifiedMap['details'] = {};
          }
        }
        processedAssetMaps.add(modifiedMap);
      }
      
      final backupInfo = BackupInfo(
        appName: 'AssetIt',
        version: packageInfo.version,
        exportDate: DateTime.now(),
        assetCount: assetMaps.length,
        financeCount: financeMaps.length,
        currencyChoiceCount: currencyChoiceMaps.length,
        baseCurrencyCount: baseCurrencyMaps.length,
        userCount: userMaps.length,
        salaryCount: salaryMaps.length,
        deviceId: 'local_device',
      );

      final backupData = {
        'backup_info': backupInfo.toMap(),
        'assets': processedAssetMaps,
        'finances': financeMaps,
        'currency_choices': currencyChoiceMaps,
        'base_currencies': baseCurrencyMaps,
        'users': userMaps,
        'asset_type_ordering': assetTypeOrderingMaps,
        'salaries': salaryMaps,
      };

      final jsonString = jsonEncode(backupData);
      
      _isPreparingData = false;
      _isExporting = true;
      notifyListeners();
      
      final encryptedBytes = await _encryptInIsolate(jsonString);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'asset_it_backup_$timestamp.aes';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(encryptedBytes);

      await Share.shareXFiles([XFile(file.path)]);

      _lastBackupDate = DateTime.now();
      
      _isExporting = false;
      notifyListeners();

      return BackupResult(
        success: true,
        message: AppStrings.backupSharedSuccessfully.tr,
        filePath: file.path,
      );
    } catch (e) {
      _isPreparingData = false;
      _isExporting = false;
      notifyListeners();
      
      return BackupResult(
        success: false,
        message: '${AppStrings.shareFailedError.tr}: ${e.toString()}',
      );
    }
  }

  Future<ImportResult> importFromFile() async {
    _isImporting = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File (.aes)',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _isImporting = false;
        notifyListeners();
        return ImportResult(
          success: false,
          error: AppStrings.noFileSelected.tr,
        );
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        _isImporting = false;
        notifyListeners();
        return ImportResult(
          success: false,
          error: AppStrings.couldNotAccessFile.tr,
        );
      }

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      final jsonString = await _decryptInIsolate(fileBytes);
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (!backupData.containsKey('backup_info') || !backupData.containsKey('assets')) {
        _isImporting = false;
        notifyListeners();
        return ImportResult(
          success: false,
          error: AppStrings.invalidBackupFormat.tr,
        );
      }

      final backupInfo = BackupInfo.fromMap(backupData['backup_info']);

      _isImporting = false;
      notifyListeners();

      return ImportResult(
        success: true,
        backupInfo: backupInfo,
      );
    } catch (e) {
      _isImporting = false;
      notifyListeners();
      
      return ImportResult(
        success: false,
        error: '${AppStrings.importFailedError.tr}: ${e.toString()}',
      );
    }
  }

  Future<ImportResult> validateBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File (.aes)',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          error: AppStrings.noFileSelected.tr,
        );
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return ImportResult(
          success: false,
          error: AppStrings.couldNotAccessFile.tr,
        );
      }

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      final jsonString = await _decryptInIsolate(fileBytes);
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (!backupData.containsKey('backup_info') || !backupData.containsKey('assets')) {
        return ImportResult(
          success: false,
          error: AppStrings.invalidBackupFormat.tr,
        );
      }

      final backupInfo = BackupInfo.fromMap(backupData['backup_info']);
      final assetCount = (backupData['assets'] as List).length;

      return ImportResult(
        success: true,
        backupInfo: backupInfo.copyWith(
          assetCount: assetCount,
        ),
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: '${AppStrings.validationFailedError.tr}: ${e.toString()}',
      );
    }
  }

  Future<ImportResult> importAndRestore() async {
    _isImporting = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File (.aes)',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _isImporting = false;
        notifyListeners();
        return ImportResult(
          success: false,
          error: AppStrings.noFileSelected.tr,
        );
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        _isImporting = false;
        notifyListeners();
        return ImportResult(
          success: false,
          error: AppStrings.couldNotAccessFile.tr,
        );
      }

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      final jsonString = await _decryptInIsolate(fileBytes);
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (!backupData.containsKey('backup_info') || !backupData.containsKey('assets')) {
        _isImporting = false;
        notifyListeners();
        return ImportResult(
          success: false,
          error: AppStrings.invalidBackupFormat.tr,
        );
      }

      final backupInfo = BackupInfo.fromMap(backupData['backup_info']);

      final restored = await restoreBackup(backupData);

      _isImporting = false;
      notifyListeners();

      return ImportResult(
        success: restored,
        backupInfo: backupInfo,
        error: restored ? null : AppStrings.importFailedError.tr,
      );
    } catch (e) {
      _isImporting = false;
      notifyListeners();
      
      return ImportResult(
        success: false,
        error: '${AppStrings.importFailedError.tr}: ${e.toString()}',
      );
    }
  }

  Future<bool> restoreBackup(Map<String, dynamic> backupData) async {
    try {
      final db = await SQLiteDatabaseManager.database;
      
      await db.transaction((txn) async {
        await txn.delete('assets');
        await txn.delete('finances');
        await txn.delete('currency_choices');
        await txn.delete('base_currencies');
        await txn.delete('users');
        await txn.delete('asset_type_ordering');
        await txn.delete('salaries');

        final baseCurrenciesList = backupData['base_currencies'] as List<dynamic>? ?? [];
        if (baseCurrenciesList.isNotEmpty) {
          for (var currencyMap in baseCurrenciesList) {
            await txn.insert('base_currencies', currencyMap as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final currencyChoicesList = backupData['currency_choices'] as List<dynamic>? ?? [];
        if (currencyChoicesList.isNotEmpty) {
          for (var choiceMap in currencyChoicesList) {
            final map = Map<String, dynamic>.from(choiceMap as Map<String, dynamic>);
            await txn.insert('currency_choices', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final usersList = backupData['users'] as List<dynamic>? ?? [];
        if (usersList.isNotEmpty) {
          for (var userMap in usersList) {
            await txn.insert('users', userMap as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final financesList = backupData['finances'] as List<dynamic>? ?? [];
        if (financesList.isNotEmpty) {
          for (var financeMap in financesList) {
            await txn.insert('finances', financeMap as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final assetsList = backupData['assets'] as List<dynamic>? ?? [];
        if (assetsList.isNotEmpty) {
          for (var assetMap in assetsList) {
            final map = Map<String, dynamic>.from(assetMap as Map<String, dynamic>);
            if (map['details'] != null && map['details'] is! String) {
              map['details'] = jsonEncode(map['details']);
            }
            if (!map.containsKey('sortOrder')) {
              map['sortOrder'] = 0;
            }
            await txn.insert('assets', map, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final assetTypeOrderingList = backupData['asset_type_ordering'] as List<dynamic>? ?? [];
        if (assetTypeOrderingList.isNotEmpty) {
          for (var orderingMap in assetTypeOrderingList) {
            await txn.insert('asset_type_ordering', orderingMap as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        final salariesList = backupData['salaries'] as List<dynamic>? ?? [];
        if (salariesList.isNotEmpty) {
          for (var salaryMap in salariesList) {
            await txn.insert('salaries', salaryMap as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });

      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  void reset() {
    _isExporting = false;
    _isImporting = false;
    _lastBackupPath = null;
    _lastBackupDate = null;
    notifyListeners();
  }
}

extension BackupInfoExtension on BackupInfo {
  BackupInfo copyWith({
    String? appName,
    String? version,
    DateTime? exportDate,
    int? assetCount,
    int? financeCount,
    int? currencyChoiceCount,
    int? baseCurrencyCount,
    int? userCount,
    int? salaryCount,
    String? deviceId,
  }) {
    return BackupInfo(
      appName: appName ?? this.appName,
      version: version ?? this.version,
      exportDate: exportDate ?? this.exportDate,
      assetCount: assetCount ?? this.assetCount,
      financeCount: financeCount ?? this.financeCount,
      currencyChoiceCount: currencyChoiceCount ?? this.currencyChoiceCount,
      baseCurrencyCount: baseCurrencyCount ?? this.baseCurrencyCount,
      userCount: userCount ?? this.userCount,
      salaryCount: salaryCount ?? this.salaryCount,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
