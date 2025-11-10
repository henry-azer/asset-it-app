class Spending {
  final String id;
  final String type;
  final double amount;
  final String notes;

  Spending({
    required this.id,
    required this.type,
    required this.amount,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'notes': notes,
    };
  }

  factory Spending.fromMap(Map<String, dynamic> map) {
    return Spending(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String? ?? '',
    );
  }

  Spending copyWith({
    String? id,
    String? type,
    double? amount,
    String? notes,
  }) {
    return Spending(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }
}
