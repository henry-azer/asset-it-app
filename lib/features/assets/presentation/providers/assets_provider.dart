import 'package:flutter/foundation.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/enums/asset_enums.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/datasources/asset_local_datasource.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/data/entities/asset_with_values.dart';
import 'package:asset_it/data/entities/asset_type_ordering.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';
import 'package:asset_it/injection_container.dart';

class AssetsProvider extends ChangeNotifier {
  final AssetLocalDataSource _dataSource = sl<AssetLocalDataSource>();
  final CurrencyChoiceProvider _currencyChoiceProvider;
  final FinanceProvider _financeProvider;

  List<Asset> _assets = [];
  List<AssetWithValues> _assetsWithValues = [];
  List<AssetTypeOrdering> _assetTypeOrderings = [];
  bool _isLoading = false;
  String? _error;

  List<Asset> get assets => _assets;

  List<AssetWithValues> get assetsWithValues => _assetsWithValues;

  List<AssetTypeOrdering> get assetTypeOrderings => _assetTypeOrderings;

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<AssetWithValues> get assetsList =>
      _assetsWithValues.where((a) => a.asset.isAsset).toList();

  List<AssetWithValues> get liabilitiesList =>
      _assetsWithValues.where((a) => a.asset.isLiability).toList();

  double get totalAssetsValue =>
      assetsList.fold(0.0, (sum, asset) => sum + asset.currentValue);

  double get totalLiabilitiesValue => liabilitiesList.fold(
      0.0, (sum, liability) => sum + liability.currentValue.abs());

  double get netWorth => totalAssetsValue - totalLiabilitiesValue;

  double get totalGainLoss =>
      _assetsWithValues
          .where((asset) => asset.asset.type != AssetType.loan && asset.asset.type != AssetType.creditCard)
          .fold(0.0, (sum, asset) => sum + asset.gainLoss);

  double get totalGainLossPercentage {
    final totalInitial = _assetsWithValues
        .where((asset) => asset.asset.type != AssetType.loan && asset.asset.type != AssetType.creditCard)
        .fold(0.0, (sum, asset) => sum + asset.asset.initialValue);
    return totalInitial != 0 ? (totalGainLoss / totalInitial) * 100 : 0;
  }

  Map<String, List<AssetWithValues>> get assetsByType {
    final Map<String, List<AssetWithValues>> grouped = {};
    for (final asset in _assetsWithValues) {
      final typeKey = asset.asset.type.name;
      grouped.putIfAbsent(typeKey, () => []);
      grouped[typeKey]!.add(asset);
    }
    return grouped;
  }

  AssetsProvider({
    required FinanceProvider financeProvider,
    required CurrencyChoiceProvider currencyChoiceProvider,
  })  : _financeProvider = financeProvider,
        _currencyChoiceProvider = currencyChoiceProvider {
    _financeProvider.addListener(_onFinancesChanged);
    _currencyChoiceProvider.addListener(_onCurrencyChoiceChanged);
  }

  void _onFinancesChanged() async {
    if (_assets.isNotEmpty) {
      for (var asset in _assets) {
        final updatedAsset = _calculateAndSetAssetValues(asset);
        await _dataSource.updateAsset(updatedAsset);
      }
      await loadAssets();
    }
  }

  void _onCurrencyChoiceChanged() {
    loadAssets();
  }

  void _calculateAssetValues() {
    _assetsWithValues = _assets
        .map((asset) => AssetWithValues(
              asset: asset,
              currentValue: asset.currentValue,
              purchaseValue: asset.purchaseValue,
            ))
        .toList();
    _sortAssets();
  }

  void _sortAssets() {
    for (var assetWithValue in _assetsWithValues) {
      final typeIndex = _assetTypeOrderings.indexWhere(
        (ordering) => ordering.assetType == assetWithValue.asset.type,
      );
      if (typeIndex == -1) {
        continue;
      }
    }
  }

  Future<void> loadAssets() async {
    final currencyChoice = _currencyChoiceProvider.activeCurrencyChoice;
    if (currencyChoice == null) {
      _assets = [];
      _assetsWithValues = [];
      _isLoading = false;
      _error = '${AppStrings.noCurrencyProfileError.tr}. ${AppStrings.setCurrencyProfileFirst.tr}.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baseCurrency = currencyChoice.baseCurrency;
      _assets = await _dataSource.getAssetsByBaseCurrency(
          currencyChoice.id, baseCurrency);
      _assetTypeOrderings = await _dataSource.getAssetTypeOrderings(currencyChoice.id);
      _assets.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _calculateAssetValues();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAsset(Asset asset) async {
    try {
      final activeCurrencyChoice = _currencyChoiceProvider.activeCurrencyChoice;
      if (activeCurrencyChoice == null) {
        _error = '${AppStrings.noCurrencyProfileError.tr}. ${AppStrings.setCurrencyProfileFirst.tr}.';
        notifyListeners();
        return false;
      }

      final assetWithCalculatedValues = _calculateAndSetAssetValues(asset);
      final assetWithCurrency =
          assetWithCalculatedValues.copyWith(baseCurrency: activeCurrencyChoice.baseCurrency);
      await _dataSource.insertAsset(assetWithCurrency, activeCurrencyChoice.id);
      await loadAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Asset _calculateAndSetAssetValues(Asset asset) {
    final assetWithValues = AssetWithValues.fromAsset(asset, _financeProvider);
    return asset.copyWith(
      calculatedCurrentValue: assetWithValues.currentValue,
      calculatedPurchaseValue: assetWithValues.purchaseValue,
      lastCalculated: DateTime.now(),
    );
  }

  Future<bool> updateAsset(Asset asset) async {
    try {
      final assetWithCalculatedValues = _calculateAndSetAssetValues(asset);
      await _dataSource.updateAsset(assetWithCalculatedValues);
      await loadAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAsset(String id) async {
    try {
      await _dataSource.deleteAsset(id);
      await loadAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  AssetWithValues? getAssetWithValuesById(String id) {
    try {
      return _assetsWithValues.firstWhere((a) => a.asset.id == id);
    } catch (e) {
      return null;
    }
  }

  Asset? getAssetById(String id) {
    try {
      return _assets.firstWhere((asset) => asset.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> reorderAssets(AssetType type, int oldIndex, int newIndex, List<AssetWithValues> assetsInGroup) async {
    if (oldIndex == newIndex) return;

    final reorderedAssets = List<AssetWithValues>.from(assetsInGroup);
    final item = reorderedAssets.removeAt(oldIndex);
    reorderedAssets.insert(newIndex, item);

    final updatedAssets = reorderedAssets.map((assetWithValue) {
      final index = reorderedAssets.indexOf(assetWithValue);
      return assetWithValue.asset.copyWith(sortOrder: index);
    }).toList();

    for (var asset in updatedAssets) {
      final assetIndex = _assets.indexWhere((a) => a.id == asset.id);
      if (assetIndex != -1) {
        _assets[assetIndex] = asset;
      }
    }
    _calculateAssetValues();
    notifyListeners();

    _dataSource.batchUpdateAssetSortOrders(updatedAssets);
  }

  Future<void> reorderAssetTypes(int oldIndex, int newIndex, List<AssetType> types) async {
    if (oldIndex == newIndex) return;

    final currencyChoice = _currencyChoiceProvider.activeCurrencyChoice;
    if (currencyChoice == null) return;

    final reorderedTypes = List<AssetType>.from(types);
    final item = reorderedTypes.removeAt(oldIndex);
    reorderedTypes.insert(newIndex, item);

    final orderings = reorderedTypes.asMap().entries.map((entry) {
      return AssetTypeOrdering(
        id: '',
        profileId: currencyChoice.id,
        assetType: entry.value,
        sortOrder: entry.key,
      );
    }).toList();

    _assetTypeOrderings = orderings;
    notifyListeners();

    _dataSource.batchUpdateAssetTypeOrderings(currencyChoice.id, orderings);
  }

  List<AssetType> getOrderedAssetTypes(Map<AssetType, List<AssetWithValues>> groupedAssets) {
    final types = groupedAssets.keys.toList();
    
    if (_assetTypeOrderings.isEmpty) {
      return types;
    }

    types.sort((a, b) {
      final aIndex = _assetTypeOrderings.indexWhere((o) => o.assetType == a);
      final bIndex = _assetTypeOrderings.indexWhere((o) => o.assetType == b);
      
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      
      return _assetTypeOrderings[aIndex].sortOrder.compareTo(_assetTypeOrderings[bIndex].sortOrder);
    });

    return types;
  }

  @override
  void dispose() {
    _financeProvider.removeListener(_onFinancesChanged);
    _currencyChoiceProvider.removeListener(_onCurrencyChoiceChanged);
    super.dispose();
  }
}
