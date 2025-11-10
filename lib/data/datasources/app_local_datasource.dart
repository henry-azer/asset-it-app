import 'package:asset_it/core/managers/storage-manager/i_storage_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/data/entities/app.dart';

abstract class AppLocalDataSource {
  Future<App?> getAppData();
  Future<void> setAppData(App app);
  Future<void> setThemeMode(String themeMode);
  Future<String> getThemeMode();
  Future<void> setLastBackupDate(DateTime date);
  Future<DateTime?> getLastBackupDate();
  Future<void> clearAppData();
}

class AppLocalDataSourceImpl implements AppLocalDataSource {
  final IStorageManager storageManager;

  AppLocalDataSourceImpl({required this.storageManager});

  @override
  Future<App?> getAppData() async {
    final appData = await storageManager.getValue<Map<String, dynamic>>(AppLocalStorageKeys.appData);
    if (appData != null) {
      return App.fromMap(appData);
    }
    return null;
  }

  @override
  Future<void> setAppData(App app) async {
    await storageManager.setValue(AppLocalStorageKeys.appData, app.toMap());
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    await storageManager.setValue(AppLocalStorageKeys.themeMode, themeMode);
  }

  @override
  Future<String> getThemeMode() async {
    return await storageManager.getValue<String>(AppLocalStorageKeys.themeMode) ?? '';
  }

  @override
  Future<void> setLastBackupDate(DateTime date) async {
    await storageManager.setValue(AppLocalStorageKeys.lastBackupDate, date.toIso8601String());
  }

  @override
  Future<DateTime?> getLastBackupDate() async {
    final dateString = await storageManager.getValue<String>(AppLocalStorageKeys.lastBackupDate);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  @override
  Future<void> clearAppData() async {
    storageManager.removeValue(AppLocalStorageKeys.appData);
    storageManager.removeValue(AppLocalStorageKeys.themeMode);
    storageManager.removeValue(AppLocalStorageKeys.lastBackupDate);
  }
}
