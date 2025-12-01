import 'package:asset_it/data/entities/income.dart';
import 'package:asset_it/data/entities/spending.dart';

class Salary {
  final String id;
  final String name;
  final double amount;
  final List<Income> incomes;
  final List<Spending> spendings;
  final DateTime dateAdded;
  final String notes;
  final int sortOrder;

  Salary({
    required this.id,
    this.name = '',
    required this.amount,
    this.incomes = const [],
    required this.spendings,
    required this.dateAdded,
    this.notes = '',
    this.sortOrder = 0,
  });

  double get totalIncomes {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  double get totalSpendings {
    return spendings.fold(0.0, (sum, spending) => sum + spending.amount);
  }

  double get remainingAmount {
    return amount - totalSpendings;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'incomes': incomes.map((i) => i.toMap()).toList(),
      'spendings': spendings.map((s) => s.toMap()).toList(),
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
      'sortOrder': sortOrder,
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      incomes: map['incomes'] != null
          ? (map['incomes'] as List<dynamic>)
              .map((i) => Income.fromMap(i as Map<String, dynamic>))
              .toList()
          : [],
      spendings: (map['spendings'] as List<dynamic>)
          .map((s) => Spending.fromMap(s as Map<String, dynamic>))
          .toList(),
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      notes: map['notes'] as String? ?? '',
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Salary copyWith({
    String? id,
    String? name,
    double? amount,
    List<Income>? incomes,
    List<Spending>? spendings,
    DateTime? dateAdded,
    String? notes,
    int? sortOrder,
  }) {
    return Salary(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      incomes: incomes ?? this.incomes,
      spendings: spendings ?? this.spendings,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
