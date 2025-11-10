import 'package:get_it/get_it.dart';
import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/managers/database-manager/sqlite_database_manager.dart';
import 'package:asset_it/core/managers/storage-manager/i_storage_manager.dart';
import 'package:asset_it/core/managers/storage-manager/local_storage_manager.dart';
import 'package:asset_it/data/datasources/app_local_datasource.dart';
import 'package:asset_it/data/datasources/asset_local_datasource.dart';
import 'package:asset_it/data/datasources/user_local_datasource.dart';
import 'package:asset_it/data/datasources/salary_local_datasource.dart';
import 'package:asset_it/data/datasources/base_currency_local_datasource.dart';
import 'package:asset_it/data/datasources/currency_choice_local_datasource.dart';
import 'package:asset_it/data/datasources/finance_local_datasource.dart';
import 'package:asset_it/core/services/currency_service.dart';

final sl = GetIt.instance;

Future<void> init() async {

  // !---- Managers ----!
  sl.registerLazySingleton<IStorageManager>(() => LocalStorageManager());
  
  // Initialize database manager
  final databaseManager = SQLiteDatabaseManager();
  await databaseManager.init();
  sl.registerLazySingleton<IDatabaseManager>(() => databaseManager);

  // !---- Data Sources ----!
  sl.registerLazySingleton<AppLocalDataSource>(() => AppLocalDataSourceImpl(storageManager: sl()));
  sl.registerLazySingleton<UserLocalDataSource>(() => UserLocalDataSourceImpl(storageManager: sl()));
  sl.registerLazySingleton<AssetLocalDataSource>(() => AssetLocalDataSourceImpl(databaseManager: sl()));
  sl.registerLazySingleton<SalaryLocalDataSource>(() => SalaryLocalDataSourceImpl(databaseManager: sl()));
  sl.registerLazySingleton<BaseCurrencyLocalDatasource>(() => BaseCurrencyLocalDatasourceImpl(databaseManager: sl()));
  sl.registerLazySingleton<CurrencyChoiceLocalDatasource>(() => CurrencyChoiceLocalDatasourceImpl(databaseManager: sl()));
  sl.registerLazySingleton<FinanceLocalDatasource>(() => FinanceLocalDatasourceImpl(databaseManager: sl()));

  // !---- Services ----!
  sl.registerLazySingleton<CurrencyService>(() => CurrencyService(sl()));

}
