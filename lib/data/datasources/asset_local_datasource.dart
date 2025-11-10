import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:asset_it/core/enums/asset_enums.dart';
import 'package:asset_it/core/managers/database-manager/i_database_manager.dart';
import 'package:asset_it/core/utils/app_local_storage_strings.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/data/entities/asset_type_ordering.dart';

abstract class AssetLocalDataSource {
  Future<List<Asset>> getAllAssets(String profileId);
  Future<List<Asset>> getAssetsByBaseCurrency(String profileId, String baseCurrency);
  Future<Asset?> getAssetById(String id);
  Future<void> insertAsset(Asset asset, String profileId);
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
  Future<void> updateAssetSortOrder(String assetId, int sortOrder);
  Future<void> batchUpdateAssetSortOrders(List<Asset> assets);
  Future<List<AssetTypeOrdering>> getAssetTypeOrderings(String profileId);
  Future<void> updateAssetTypeOrdering(String profileId, AssetType assetType, int sortOrder);
  Future<void> batchUpdateAssetTypeOrderings(String profileId, List<AssetTypeOrdering> orderings);
}

class AssetLocalDataSourceImpl implements AssetLocalDataSource {
  final IDatabaseManager databaseManager;

  AssetLocalDataSourceImpl({required this.databaseManager});

  @override
  Future<List<Asset>> getAllAssets(String profileId) async {
    final results = await databaseManager.query(
      AppLocalStorageKeys.assetsTable,
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
    return results.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (modifiedMap['details'] != null && modifiedMap['details'] is String) {
        modifiedMap['details'] = json.decode(modifiedMap['details']);
      }
      return Asset.fromMap(modifiedMap);
    }).toList();
  }

  @override
  Future<List<Asset>> getAssetsByBaseCurrency(String profileId, String baseCurrency) async {
    final results = await databaseManager.query(
      AppLocalStorageKeys.assetsTable,
      where: 'profileId = ? AND baseCurrency = ?',
      whereArgs: [profileId, baseCurrency],
    );
    return results.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (modifiedMap['details'] != null && modifiedMap['details'] is String) {
        modifiedMap['details'] = json.decode(modifiedMap['details']);
      }
      return Asset.fromMap(modifiedMap);
    }).toList();
  }

  @override
  Future<Asset?> getAssetById(String id) async {
    final results = await databaseManager.query(
      AppLocalStorageKeys.assetsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) return null;
    
    final map = Map<String, dynamic>.from(results.first);
    if (map['details'] != null && map['details'] is String) {
      map['details'] = json.decode(map['details']);
    }
    return Asset.fromMap(map);
  }

  @override
  Future<void> insertAsset(Asset asset, String profileId) async {
    final map = asset.toMap();
    map['profileId'] = profileId;
    if (map['details'] != null) {
      map['details'] = json.encode(map['details']);
    }
    await databaseManager.insert(AppLocalStorageKeys.assetsTable, map);
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    final existingResults = await databaseManager.query(
      AppLocalStorageKeys.assetsTable,
      where: 'id = ?',
      whereArgs: [asset.id],
    );
    
    if (existingResults.isEmpty) {
      throw Exception('Asset with id ${asset.id} not found');
    }
    
    final existingData = existingResults.first;
    final profileId = existingData['profileId'];
    
    final map = asset.toMap();
    map['profileId'] = profileId;
    
    if (map['details'] != null) {
      map['details'] = json.encode(map['details']);
    }
    
    await databaseManager.update(
      AppLocalStorageKeys.assetsTable,
      map,
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  @override
  Future<void> deleteAsset(String id) async {
    await databaseManager.delete(
      AppLocalStorageKeys.assetsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateAssetSortOrder(String assetId, int sortOrder) async {
    await databaseManager.update(
      AppLocalStorageKeys.assetsTable,
      {'sortOrder': sortOrder},
      where: 'id = ?',
      whereArgs: [assetId],
    );
  }

  @override
  Future<void> batchUpdateAssetSortOrders(List<Asset> assets) async {
    for (int i = 0; i < assets.length; i++) {
      await updateAssetSortOrder(assets[i].id, i);
    }
  }

  @override
  Future<List<AssetTypeOrdering>> getAssetTypeOrderings(String profileId) async {
    final results = await databaseManager.query(
      'asset_type_ordering',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'sortOrder ASC',
    );
    return results.map((map) => AssetTypeOrdering.fromMap(map)).toList();
  }

  @override
  Future<void> updateAssetTypeOrdering(String profileId, AssetType assetType, int sortOrder) async {
    final existing = await databaseManager.query(
      'asset_type_ordering',
      where: 'profileId = ? AND assetType = ?',
      whereArgs: [profileId, assetType.name],
    );

    if (existing.isEmpty) {
      await databaseManager.insert(
        'asset_type_ordering',
        {
          'id': const Uuid().v4(),
          'profileId': profileId,
          'assetType': assetType.name,
          'sortOrder': sortOrder,
        },
      );
    } else {
      await databaseManager.update(
        'asset_type_ordering',
        {'sortOrder': sortOrder},
        where: 'profileId = ? AND assetType = ?',
        whereArgs: [profileId, assetType.name],
      );
    }
  }

  @override
  Future<void> batchUpdateAssetTypeOrderings(String profileId, List<AssetTypeOrdering> orderings) async {
    for (int i = 0; i < orderings.length; i++) {
      await updateAssetTypeOrdering(profileId, orderings[i].assetType, i);
    }
  }
}
