class CurrencyChoice {
  final String id;
  final String baseCurrency;
  final String currencyName;
  final String currencySymbol;
  final bool isActive;
  final DateTime createdDate;
  final DateTime? lastAccessedDate;

  CurrencyChoice({
    required this.id,
    required this.baseCurrency,
    required this.currencyName,
    required this.currencySymbol,
    this.isActive = false,
    required this.createdDate,
    this.lastAccessedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseCurrency': baseCurrency,
      'currencyName': currencyName,
      'currencySymbol': currencySymbol,
      'isActive': isActive ? 1 : 0,
      'createdDate': createdDate.toIso8601String(),
      'lastAccessedDate': lastAccessedDate?.toIso8601String(),
    };
  }

  factory CurrencyChoice.fromMap(Map<String, dynamic> map) {
    return CurrencyChoice(
      id: map['id'] as String,
      baseCurrency: map['baseCurrency'] as String,
      currencyName: map['currencyName'] as String,
      currencySymbol: map['currencySymbol'] as String,
      isActive: (map['isActive'] as int) == 1,
      createdDate: DateTime.parse(map['createdDate'] as String),
      lastAccessedDate: map['lastAccessedDate'] != null
          ? DateTime.parse(map['lastAccessedDate'] as String)
          : null,
    );
  }

  CurrencyChoice copyWith({
    String? id,
    String? baseCurrency,
    String? currencyName,
    String? currencySymbol,
    bool? isActive,
    DateTime? createdDate,
    DateTime? lastAccessedDate,
  }) {
    return CurrencyChoice(
      id: id ?? this.id,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      currencyName: currencyName ?? this.currencyName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      lastAccessedDate: lastAccessedDate ?? this.lastAccessedDate,
    );
  }
  
  @override
  String toString() {
    return 'CurrencyChoice{id: $id, baseCurrency: $baseCurrency, currencyName: $currencyName, currencySymbol: $currencySymbol, isActive: $isActive}';
  }
}
