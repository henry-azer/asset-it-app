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
      _salaries.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
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
      
      await _dataSource.saveSalary(salary, profileId);
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
      
      for (final salary in _salaries) {
        await _dataSource.saveSalary(salary, profileId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
