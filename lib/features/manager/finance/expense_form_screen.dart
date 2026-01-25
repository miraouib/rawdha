import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/expense_model.dart';
import '../../../services/finance_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/date_helper.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ExpenseType _selectedType = ExpenseType.other;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  final FinanceService _financeService = FinanceService();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.error_rawdha_id'.tr())));
      }
      return;
    }

    try {
      final expense = ExpenseModel(
        rawdhaId: rawdhaId,
        id: '',
        type: _selectedType,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _financeService.addExpense(expense);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('finance.payment_saved'.tr()))); // Using generic success message as we don't have separate key yet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${"common.error".tr()}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('finance.new_expense'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Type Selector
                      DropdownButtonFormField<ExpenseType>(
                        value: _selectedType,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'common.filter'.tr(), prefixIcon: const Icon(Icons.category)),
                        items: ExpenseType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              ExpenseModel(
                                rawdhaId: '',
                                id: '', 
                                type: type, 
                                amount: 0, 
                                date: DateTime.now(), 
                                createdAt: DateTime.now()
                              ).typeLabel
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: '${"finance.amount".tr()} (${"finance.currency".tr()})', prefixIcon: const Icon(Icons.attach_money)),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'finance.required'.tr();
                          if (double.tryParse(v.replaceAll(',', '.')) == null) return 'finance.invalid'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: 'finance.payment_date'.tr(), prefixIcon: const Icon(Icons.calendar_today)),
                          child: Text(DateHelper.formatDateLong(context, _selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'finance.note_optional'.tr(), prefixIcon: const Icon(Icons.description)),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('common.save'.tr(), style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
