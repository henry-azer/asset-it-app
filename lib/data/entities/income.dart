class Income {
  final String id;
  final String type;
  final double amount;
  final String notes;
  final int sortOrder;

  Income({
    required this.id,
    required this.type,
    required this.amount,
    this.notes = '',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'notes': notes,
      'sortOrder': sortOrder,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String? ?? '',
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Income copyWith({
    String? id,
    String? type,
    double? amount,
    String? notes,
    int? sortOrder,
  }) {
    return Income(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
