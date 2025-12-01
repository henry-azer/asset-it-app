import 'package:flutter/foundation.dart';
import 'package:asset_it/data/datasources/salary_local_datasource.dart';
import 'package:asset_it/data/entities/salary.dart';
import 'package:asset_it/features/finance/providers/currency_choice_provider.dart';

class SalaryProvider extends ChangeNotifier {
  final SalaryLocalDataSource _dataSource;
  final CurrencyChoiceProvider _currencyChoiceProvider;

  List<Salary> _salaries = [];
  bool _isLoading = false;
  String? _error;

  List<Salary> get salaries => _salaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalSalaries => _salaries.fold(0.0, (sum, salary) => sum + salary.amount);
  double get totalSpendings => _salaries.fold(0.0, (sum, salary) => sum + salary.totalSpendings);
  double get totalRemaining => _salaries.fold(0.0, (sum, salary) => sum + salary.remainingAmount);

  SalaryProvider(this._dataSource, this._currencyChoiceProvider);

  Future<void> loadSalaries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profileId = _currencyChoiceProvider.activeCurrencyChoice?.id ?? '';
      if (profileId.isEmpty) {
        _salaries = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      _salaries = await _dataSource.getSalaries(profileId);
      _salaries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSalary(Salary salary) async {
    try {
      final profileId = _currencyChoiceProvider.activeCurrencyChoice?.id ?? '';
      if (profileId.isEmpty) return false;
      
      final maxSortOrder = _salaries.isEmpty
          ? -1
          : _salaries.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
      
      final salaryWithSortOrder = salary.copyWith(sortOrder: maxSortOrder + 1);
      await _dataSource.saveSalary(salaryWithSortOrder, profileId);
      await loadSalaries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSalary(Salary salary) async {
    try {
      final profileId = _currencyChoiceProvider.activeCurrencyChoice?.id ?? '';
      if (profileId.isEmpty) return false;
      
      await _dataSource.saveSalary(salary, profileId);
      await loadSalaries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSalary(String id) async {
    try {
      await _dataSource.deleteSalary(id);
      await loadSalaries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void reorderSalaries(int oldIndex, int newIndex) {
    // Validate indices
    if (oldIndex < 0 || oldIndex >= _salaries.length) {
      return;
    }
    
    // Adjust newIndex if moving down (standard Flutter ReorderableList behavior)
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    // Ensure newIndex is within valid range
    if (newIndex < 0 || newIndex >= _salaries.length) {
      return;
    }
    
    // Don't do anything if indices are the same after adjustment
    if (oldIndex == newIndex) {
      return;
    }
    
    try {
      final salary = _salaries.removeAt(oldIndex);
      _salaries.insert(newIndex, salary);
      notifyListeners();
      
      // Save the new order to local storage
      _saveReorderedSalaries();
    } catch (e) {
      // If there's an error, reload salaries to restore correct state
      loadSalaries();
    }
  }

  Future<void> _saveReorderedSalaries() async {
    try {
      final profileId = _currencyChoiceProvider.activeCurrencyChoice?.id ?? '';
      if (profileId.isEmpty) return;
      
      for (int i = 0; i < _salaries.length; i++) {
        final updatedSalary = _salaries[i].copyWith(sortOrder: i);
        _salaries[i] = updatedSalary;
        await _dataSource.saveSalary(updatedSalary, profileId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> reorderSpendings(String salaryId, int oldIndex, int newIndex) async {
    final salaryIndex = _salaries.indexWhere((s) => s.id == salaryId);
    if (salaryIndex == -1) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final salary = _salaries[salaryIndex];
    final spendings = List.from(salary.spendings)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    if (oldIndex < 0 || oldIndex >= spendings.length) return;
    if (newIndex < 0 || newIndex >= spendings.length) return;
    if (oldIndex == newIndex) return;

    final spending = spendings.removeAt(oldIndex);
    spendings.insert(newIndex, spending);

    final updatedSpendings = spendings.asMap().entries.map((entry) {
      return entry.value.copyWith(sortOrder: entry.key);
    }).toList();

    final updatedSalary = salary.copyWith(spendings: List.from(updatedSpendings));
    _salaries[salaryIndex] = updatedSalary;
    notifyListeners();

    try {
      final profileId = _currencyChoiceProvider.activeCurrencyChoice?.id ?? '';
      if (profileId.isNotEmpty) {
        await _dataSource.saveSalary(updatedSalary, profileId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
