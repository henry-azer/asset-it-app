import 'package:asset_it/core/enums/asset_enums.dart';

class Asset {
  final String id;
  final String name;
  final AssetType type;
  final double initialValue;
  final DateTime dateAdded;
  final String? notes;
  final Map<String, dynamic>? details;
  final String? baseCurrency;
  final int sortOrder;
  final double? calculatedCurrentValue;
  final double? calculatedPurchaseValue;
  final DateTime? lastCalculated;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.initialValue,
    required this.dateAdded,
    this.notes,
    this.details,
    this.baseCurrency,
    this.sortOrder = 0,
    this.calculatedCurrentValue,
    this.calculatedPurchaseValue,
    this.lastCalculated,
  });

  bool get isLiability => type.isLiability;
  
  bool get isAsset => type.isAsset;
  
  String? get goldKarat => details?['karat'];
  double? get goldGrams => details?['grams'];
  double? get goldPricePerGram => details?['pricePerGram'];
  
  String? get stockSymbol => details?['symbol'];
  double? get stockShares => details?['shares'];
  double? get stockPricePerShare => details?['pricePerShare'];
  
  String? get bankName => details?['bankName'];
  String? get bankAccountType => details?['accountType'];
  
  double? get loanInterestRate => details?['interestRate'];
  
  double? get creditLimit => details?['creditLimit'];
  double? get creditUsed => details?['used'];
  double? get creditAvailable => creditLimit != null && creditUsed != null 
      ? creditLimit! - creditUsed! 
      : null;
  
  String? get currency => details?['currency'];
  double? get currencyAmount => details?['currencyAmount'];
  double? get purchaseRate => details?['purchaseRate'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialValue': initialValue,
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
      'details': details,
      'baseCurrency': baseCurrency,
      'sortOrder': sortOrder,
      'calculatedCurrentValue': calculatedCurrentValue,
      'calculatedPurchaseValue': calculatedPurchaseValue,
      'lastCalculated': lastCalculated?.toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AssetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AssetType.cash,
      ),
      initialValue: (map['initialValue'] as num).toDouble(),
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      notes: map['notes'] as String?,
      details: map['details'] as Map<String, dynamic>?,
      baseCurrency: map['baseCurrency'] as String?,
      sortOrder: (map['sortOrder'] as int?) ?? 0,
      calculatedCurrentValue: map['calculatedCurrentValue'] != null 
          ? (map['calculatedCurrentValue'] as num).toDouble() 
          : null,
      calculatedPurchaseValue: map['calculatedPurchaseValue'] != null 
          ? (map['calculatedPurchaseValue'] as num).toDouble() 
          : null,
      lastCalculated: map['lastCalculated'] != null 
          ? DateTime.parse(map['lastCalculated'] as String) 
          : null,
    );
  }

  Asset copyWith({
    String? id,
    String? name,
    AssetType? type,
    double? initialValue,
    DateTime? dateAdded,
    String? notes,
    Map<String, dynamic>? details,
    String? baseCurrency,
    int? sortOrder,
    double? calculatedCurrentValue,
    double? calculatedPurchaseValue,
    DateTime? lastCalculated,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialValue: initialValue ?? this.initialValue,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
      details: details ?? this.details,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      sortOrder: sortOrder ?? this.sortOrder,
      calculatedCurrentValue: calculatedCurrentValue ?? this.calculatedCurrentValue,
      calculatedPurchaseValue: calculatedPurchaseValue ?? this.calculatedPurchaseValue,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }
  
  double get currentValue => calculatedCurrentValue ?? initialValue;
  double get purchaseValue => calculatedPurchaseValue ?? initialValue;
  double get gainLoss => currentValue - purchaseValue;
  double get gainLossPercentage => purchaseValue != 0 ? (gainLoss / purchaseValue) * 100 : 0;
  
  @override
  String toString() {
    return 'Asset{id: $id, name: $name, type: ${type.name}, initialValue: $initialValue, dateAdded: $dateAdded, baseCurrency: $baseCurrency, details: $details}';
  }
}
