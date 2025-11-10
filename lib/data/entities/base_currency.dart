class BaseCurrency {
  final String code;
  final String name;
  final String symbol;
  final bool isCustom;
  final DateTime lastUpdated;

  BaseCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    this.isCustom = false,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'isCustom': isCustom ? 1 : 0,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BaseCurrency.fromMap(Map<String, dynamic> map) {
    return BaseCurrency(
      code: map['code'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String,
      isCustom: (map['isCustom'] as int) == 1,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  BaseCurrency copyWith({
    String? code,
    String? name,
    String? symbol,
    bool? isCustom,
    DateTime? lastUpdated,
  }) {
    return BaseCurrency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      isCustom: isCustom ?? this.isCustom,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
