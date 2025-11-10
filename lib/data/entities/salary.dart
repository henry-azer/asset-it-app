import 'package:asset_it/data/entities/spending.dart';

class Salary {
  final String id;
  final double amount;
  final List<Spending> spendings;
  final DateTime dateAdded;
  final String notes;

  Salary({
    required this.id,
    required this.amount,
    required this.spendings,
    required this.dateAdded,
    this.notes = '',
  });

  double get totalSpendings {
    return spendings.fold(0.0, (sum, spending) => sum + spending.amount);
  }

  double get remainingAmount {
    return amount - totalSpendings;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'spendings': spendings.map((s) => s.toMap()).toList(),
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      spendings: (map['spendings'] as List<dynamic>)
          .map((s) => Spending.fromMap(s as Map<String, dynamic>))
          .toList(),
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      notes: map['notes'] as String? ?? '',
    );
  }

  Salary copyWith({
    String? id,
    double? amount,
    List<Spending>? spendings,
    DateTime? dateAdded,
    String? notes,
  }) {
    return Salary(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      spendings: spendings ?? this.spendings,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
    );
  }
}
