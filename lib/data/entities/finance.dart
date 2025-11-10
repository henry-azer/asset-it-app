import 'dart:convert';
import 'package:asset_it/core/enums/finance_enums.dart';

class Finance {
  final String id;
  final FinanceType type;
  final String code;
  final String? name;
  final double value;
  final String? baseCurrency;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  Finance({
    required this.id,
    required this.type,
    required this.code,
    this.name,
    required this.value,
    this.baseCurrency,
    required this.lastUpdated,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'code': code,
      'name': name,
      'value': value,
      'baseCurrency': baseCurrency,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata != null ? json.encode(metadata) : null,
    };
  }

  factory Finance.fromMap(Map<String, dynamic> map) {
    return Finance(
      id: map['id'] as String,
      type: FinanceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FinanceType.currency,
      ),
      code: map['code'] as String,
      name: map['name'] as String?,
      value: (map['value'] as num).toDouble(),
      baseCurrency: map['baseCurrency'] as String?,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      metadata: map['metadata'] != null && map['metadata'] is String
        ? json.decode(map['metadata']) as Map<String, dynamic>?
        : (map['metadata'] as Map<String, dynamic>?),
    );
  }

  Finance copyWith({
    String? id,
    FinanceType? type,
    String? code,
    String? name,
    double? value,
    String? baseCurrency,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return Finance(
      id: id ?? this.id,
      type: type ?? this.type,
      code: code ?? this.code,
      name: name ?? this.name,
      value: value ?? this.value,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }
}
