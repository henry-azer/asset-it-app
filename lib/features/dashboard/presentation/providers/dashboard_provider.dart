import 'package:flutter/foundation.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/data/entities/asset_with_values.dart';
import 'package:asset_it/core/enums/asset_enums.dart';

class DashboardProvider extends ChangeNotifier {
  List<AssetWithValues> _assetsWithValues = [];

  List<Asset> get assets => _assetsWithValues.map((a) => a.asset).toList();
  List<AssetWithValues> get assetsWithValues => _assetsWithValues;

  void updateAssets(List<AssetWithValues> assetsWithValues) {
    _assetsWithValues = assetsWithValues;
    notifyListeners();
  }

  double get totalAssetsValue => 
    _assetsWithValues.where((a) => a.asset.isAsset).fold(0.0, (sum, asset) => sum + asset.currentValue);

  double get totalLiabilitiesValue => 
    _assetsWithValues.where((a) => a.asset.isLiability).fold(0.0, (sum, liability) => sum + liability.currentValue.abs());

  double get netWorth => totalAssetsValue - totalLiabilitiesValue;

  double get totalGainLoss => 
    _assetsWithValues.fold(0.0, (sum, asset) => sum + asset.gainLoss);

  double get totalGainLossPercentage {
    final totalInitial = _assetsWithValues.fold(0.0, (sum, asset) => sum + asset.asset.initialValue);
    return totalInitial != 0 ? (totalGainLoss / totalInitial) * 100 : 0;
  }

  Map<AssetType, double> get assetDistribution {
    final distribution = <AssetType, double>{};
    for (var asset in _assetsWithValues.where((a) => a.asset.isAsset)) {
      distribution[asset.asset.type] = (distribution[asset.asset.type] ?? 0) + asset.currentValue;
    }
    return distribution;
  }

  Map<AssetType, double> get assetDistributionPercentage {
    final distribution = assetDistribution;
    final total = totalAssetsValue;
    if (total == 0) return {};
    
    return distribution.map((key, value) => 
      MapEntry(key, (value / total) * 100));
  }

  Map<AssetType, int> get assetCount {
    final count = <AssetType, int>{};
    for (var asset in _assetsWithValues) {
      count[asset.asset.type] = (count[asset.asset.type] ?? 0) + 1;
    }
    return count;
  }

  List<Asset> get recentAssets {
    final sorted = List<AssetWithValues>.from(_assetsWithValues);
    sorted.sort((a, b) => b.asset.dateAdded.compareTo(a.asset.dateAdded));
    return sorted.take(5).map((a) => a.asset).toList();
  }
  
  List<AssetWithValues> get topPerformers {
    final assets = _assetsWithValues.where((a) => a.gainLoss > 0).toList();
    assets.sort((a, b) => b.gainLoss.compareTo(a.gainLoss));
    return assets.take(5).toList();
  }
  
  List<AssetWithValues> get worstPerformers {
    final assets = _assetsWithValues.where((a) => a.gainLoss < 0).toList();
    assets.sort((a, b) => a.gainLoss.compareTo(b.gainLoss));
    return assets.take(5).toList();
  }
  
  double get averageGainLossPercentage {
    if (_assetsWithValues.isEmpty) return 0;
    
    double totalPercentage = 0;
    int count = 0;
    
    for (var asset in _assetsWithValues) {
      if (asset.asset.initialValue != 0) {
        totalPercentage += (asset.gainLoss / asset.asset.initialValue) * 100;
        count++;
      }
    }
    
    return count > 0 ? totalPercentage / count : 0;
  }
  
  Map<AssetType, double> get gainLossByType {
    final gainLoss = <AssetType, double>{};
    for (var asset in _assetsWithValues) {
      gainLoss[asset.asset.type] = (gainLoss[asset.asset.type] ?? 0) + asset.gainLoss;
    }
    return gainLoss;
  }
  
  int get totalAssetCount => _assetsWithValues.where((a) => a.asset.isAsset).length;
  
  int get totalLiabilityCount => _assetsWithValues.where((a) => a.asset.isLiability).length;
  
  double get liquidityRatio {
    final liquidAssets = _assetsWithValues
        .where((a) => a.asset.isAsset && 
               (a.asset.type == AssetType.cash || 
                a.asset.type == AssetType.bankAccount))
        .fold(0.0, (sum, asset) => sum + asset.currentValue);
    
    return totalLiabilitiesValue > 0 ? liquidAssets / totalLiabilitiesValue : 0;
  }
  
  double get debtToAssetRatio {
    return totalAssetsValue > 0 ? totalLiabilitiesValue / totalAssetsValue : 0;
  }
}
