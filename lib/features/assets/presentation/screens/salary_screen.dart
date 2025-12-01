import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/data/entities/income.dart';
import 'package:asset_it/data/entities/salary.dart';
import 'package:asset_it/data/entities/spending.dart';
import 'package:asset_it/features/assets/presentation/providers/salary_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SalaryScreen extends StatefulWidget {
  final Salary? salaryToEdit;

  const SalaryScreen({super.key, this.salaryToEdit});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<IncomeFormData> _incomes = [];
  final List<SpendingFormData> _spendings = [];
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.salaryToEdit != null) {
      _nameController.text = widget.salaryToEdit!.name;
      final sortedIncomes = List.from(widget.salaryToEdit!.incomes)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _incomes.addAll(
        sortedIncomes.map(
          (i) {
            final income = IncomeFormData(
              typeController: TextEditingController(text: i.type),
              amountController: TextEditingController(text: i.amount.toString()),
            );
            income.typeController.addListener(_validateForm);
            income.amountController.addListener(_validateForm);
            return income;
          },
        ),
      );
      final sortedSpendings = List.from(widget.salaryToEdit!.spendings)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _spendings.addAll(
        sortedSpendings.map(
          (s) {
            final spending = SpendingFormData(
              typeController: TextEditingController(text: s.type),
              amountController: TextEditingController(text: s.amount.toString()),
            );
            spending.typeController.addListener(_validateForm);
            spending.amountController.addListener(_validateForm);
            return spending;
          },
        ),
      );
    }

    if (_incomes.isEmpty) {
      _addIncomeField();
    }

    if (_spendings.isEmpty) {
      _addSpendingField();
    }

    _nameController.addListener(_validateForm);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var income in _incomes) {
      income.typeController.dispose();
      income.amountController.dispose();
    }
    for (var spending in _spendings) {
      spending.typeController.dispose();
      spending.amountController.dispose();
    }
    super.dispose();
  }

  double get _totalIncomes {
    return _incomes.fold(0.0, (sum, i) => sum + (double.tryParse(i.amountController.text) ?? 0.0));
  }

  double get _totalSpendings {
    return _spendings.fold(0.0, (sum, s) => sum + (double.tryParse(s.amountController.text) ?? 0.0));
  }

  void _validateForm() {
    bool isValid = true;

    bool hasAtLeastOneValidIncome = false;
    for (var income in _incomes) {
      final hasType = income.typeController.text.isNotEmpty;
      final hasAmount = income.amountController.text.isNotEmpty;
      final validAmount = double.tryParse(income.amountController.text) != null;

      if (hasType && hasAmount && validAmount) {
        hasAtLeastOneValidIncome = true;
      } else if (hasType || hasAmount) {
        if (!hasType || !hasAmount || !validAmount) {
          isValid = false;
          break;
        }
      }
    }

    if (!hasAtLeastOneValidIncome) {
      isValid = false;
    }

    for (var spending in _spendings) {
      final hasType = spending.typeController.text.isNotEmpty;
      final hasAmount = spending.amountController.text.isNotEmpty;
      final validAmount = double.tryParse(spending.amountController.text) != null;

      if (hasType || hasAmount) {
        if (!hasType || !hasAmount || !validAmount) {
          isValid = false;
          break;
        }
      }
    }

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _addIncomeField() {
    final newIncome = IncomeFormData(
      typeController: TextEditingController(),
      amountController: TextEditingController(),
    );
    
    newIncome.typeController.addListener(_validateForm);
    newIncome.amountController.addListener(_validateForm);
    
    setState(() {
      _incomes.add(newIncome);
    });
  }

  void _removeIncomeField(int index) {
    if (_incomes.length > 1) {
      setState(() {
        _incomes[index].typeController.dispose();
        _incomes[index].amountController.dispose();
        _incomes.removeAt(index);
      });
      _validateForm();
    }
  }

  void _addSpendingField() {
    final newSpending = SpendingFormData(
      typeController: TextEditingController(),
      amountController: TextEditingController(),
    );
    
    newSpending.typeController.addListener(_validateForm);
    newSpending.amountController.addListener(_validateForm);
    
    setState(() {
      _spendings.add(newSpending);
    });
  }

  void _removeSpendingField(int index) {
    if (_spendings.length > 1) {
      setState(() {
        _spendings[index].typeController.dispose();
        _spendings[index].amountController.dispose();
        _spendings.removeAt(index);
      });
      _validateForm();
    }
  }

  Future<void> _saveSalary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final filteredIncomes = _incomes
        .where((i) => i.typeController.text.isNotEmpty && i.amountController.text.isNotEmpty)
        .toList();
    final incomes = filteredIncomes
        .asMap()
        .entries
        .map((entry) => Income(
              id: const Uuid().v4(),
              type: entry.value.typeController.text,
              amount: double.tryParse(entry.value.amountController.text) ?? 0.0,
              sortOrder: entry.key,
            ))
        .toList();
    final salaryAmount = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final filteredSpendings = _spendings
        .where((s) => s.typeController.text.isNotEmpty && s.amountController.text.isNotEmpty)
        .toList();
    final spendings = filteredSpendings
        .asMap()
        .entries
        .map((entry) => Spending(
              id: const Uuid().v4(),
              type: entry.value.typeController.text,
              amount: double.tryParse(entry.value.amountController.text) ?? 0.0,
              sortOrder: entry.key,
            ))
        .toList();

    final salary = Salary(
      id: widget.salaryToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text,
      amount: salaryAmount,
      incomes: incomes,
      spendings: spendings,
      dateAdded: widget.salaryToEdit?.dateAdded ?? DateTime.now(),
    );

    final provider = Provider.of<SalaryProvider>(context, listen: false);
    final success = widget.salaryToEdit != null
        ? await provider.updateSalary(salary)
        : await provider.addSalary(salary);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.salaryToEdit != null
                  ? AppStrings.salaryUpdatedSuccessfully.tr
                  : AppStrings.salaryAddedSuccessfully.tr,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.salaryToEdit != null
                  ? AppStrings.failedToUpdateSalary.tr
                  : AppStrings.failedToAddSalary.tr,
            ),
          ),
        );
      }
    }
  }

  Widget _buildHeader(bool isDark) {
    final isEdit = widget.salaryToEdit != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isEdit ? AppStrings.updateSalary.tr : AppStrings.newSalary.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (isEdit)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: _confirmDelete,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                  children: [
                    _buildNameCard(isDark),
                    const SizedBox(height: 16),
                    _buildIncomesCard(isDark),
                    const SizedBox(height: 16),
                    _buildSpendingsCard(isDark),
                    const SizedBox(height: 16),
                    _buildSummaryCard(isDark),
                    const SizedBox(height: 16),
                    _buildSaveButton(isDark),
                    const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.incomes.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _totalIncomes.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._incomes.asMap().entries.map((entry) {
            final index = entry.key;
            final income = entry.value;
            return _buildIncomeField(income, index, isDark);
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addIncomeField,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.addMore.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeField(IncomeFormData income, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1329) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: income.typeController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.enterIncomeType.tr,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.green.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) => _validateForm(),
                ),
              ),
              if (_incomes.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeIncomeField(index),
                  icon: const Icon(Icons.remove_circle, color: Colors.grey),
                  tooltip: AppStrings.removeIncome.tr,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: income.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.enterIncomeAmount.tr,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.green.shade400,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              _validateForm();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.spendings.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _totalSpendings.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._spendings.asMap().entries.map((entry) {
            final index = entry.key;
            final spending = entry.value;
            return _buildSpendingField(spending, index, isDark);
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addSpendingField,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.addMore.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingField(SpendingFormData spending, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1329) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: spending.typeController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.enterSpendingType.tr,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) => _validateForm(),
                ),
              ),
              if (_spendings.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeSpendingField(index),
                  icon: const Icon(Icons.remove_circle, color: Colors.grey),
                  tooltip: AppStrings.removeSpending.tr,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: spending.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.enterSpendingAmount.tr,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.blue.shade400,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              _validateForm();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.label_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.salaryName.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.enterSalaryName.tr,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F1329) : Colors.grey.shade100,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue.shade400,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return StatefulBuilder(
      builder: (context, setState) {
        final salaryAmount = _totalIncomes;
        final totalSpendings = _spendings.fold<double>(
          0.0,
          (sum, s) => sum + (double.tryParse(s.amountController.text) ?? 0.0),
        );
        final remaining = salaryAmount - totalSpendings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.salaryAmount.tr,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                salaryAmount.toStringAsFixed(2),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalSpendings.tr,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                totalSpendings.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(color: isDark ? Colors.white38 : Colors.grey.shade300, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.remainingAmount.tr,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                remaining.toStringAsFixed(2),
                style: TextStyle(
                  color: remaining >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final isEdit = widget.salaryToEdit != null;
    final isEnabled = _isFormValid && !_isLoading;

    return Container(
      width: double.infinity,
      decoration: isEnabled
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: ElevatedButton(
        onPressed: isEnabled ? _saveSalary : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? Colors.transparent
              : (isDark ? const Color(0xFF1A1F3A) : Colors.grey.shade200),
          foregroundColor: isEnabled
              ? Colors.white
              : (isDark ? Colors.white38 : Colors.grey.shade400),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEdit ? AppStrings.update.tr : AppStrings.save.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.deleteSalary.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.deleteSalaryConfirmation.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1329)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.cancel.tr,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.delete.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && widget.salaryToEdit != null) {
      setState(() {
        _isDeleting = true;
      });

      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      final success = await salaryProvider.deleteSalary(widget.salaryToEdit!.id);

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.salaryDeletedSuccessfully.tr),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.failedToDeleteSalary.tr),
            ),
          );
        }
      }
    }
  }
}

class IncomeFormData {
  final TextEditingController typeController;
  final TextEditingController amountController;

  IncomeFormData({
    required this.typeController,
    required this.amountController,
  });
}

class SpendingFormData {
  final TextEditingController typeController;
  final TextEditingController amountController;

  SpendingFormData({
    required this.typeController,
    required this.amountController,
  });
}
