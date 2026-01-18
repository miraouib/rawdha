import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/expense_model.dart';
import '../../../services/finance_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class FinanceExpensesScreen extends ConsumerStatefulWidget {
  const FinanceExpensesScreen({super.key});

  @override
  ConsumerState<FinanceExpensesScreen> createState() => _FinanceExpensesScreenState();
}

class _FinanceExpensesScreenState extends ConsumerState<FinanceExpensesScreen> {
  DateTime _currentMonth = DateTime.now();
  final FinanceService _financeService = FinanceService();

  void _changeMonth(int increment) {
    final config = ref.read(schoolConfigProvider).value;
    final startMonth = config?.paymentStartMonth ?? 9;
    
    final now = DateTime.now();
    final startYear = now.month >= startMonth ? now.year : now.year - 1;
    final startDate = DateTime(startYear, startMonth, 1);

    final newMonth = DateTime(_currentMonth.year, _currentMonth.month + increment);
    
    if (increment < 0 && newMonth.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de l\'année scolaire atteinte')),
      );
      return;
    }

    setState(() {
      _currentMonth = newMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('finance.expenses'.tr()),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Text(
                  DateFormat('MMMM yyyy', 'fr').format(_currentMonth).toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: _financeService.getExpensesByMonth(ref.watch(currentRawdhaIdProvider) ?? '', _currentMonth.month, _currentMonth.year),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${"common.error".tr()}: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final expenses = snapshot.data!;
                final totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);

                final expensesByType = <ExpenseType, double>{};
                for (var e in expenses) {
                  expensesByType[e.type] = (expensesByType[e.type] ?? 0) + e.amount;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTotalCard(totalAmount),
                      const SizedBox(height: 16),
                      _buildBreakdown(expensesByType),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('finance.month_details'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      ...expenses.map((e) => _ExpenseItem(expense: e)),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('expense_add'),
        backgroundColor: AppTheme.accentOrange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentOrange, AppTheme.accentYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.gradientCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('finance.total_expenses'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                const Icon(Icons.trending_down, color: Colors.white, size: 24),
              ],
            ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${total.toStringAsFixed(2)} ${"finance.currency".tr()}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(Map<ExpenseType, double> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: data.entries.map((entry) {
            final typeLabel = ExpenseModel(rawdhaId: '', id: '', type: entry.key, amount: 0, date: DateTime.now(), createdAt: DateTime.now()).typeLabel;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('${entry.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text('finance.no_expenses'.tr(), style: const TextStyle(fontSize: 18, color: AppTheme.textGray)),
        ],
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
          child: Icon(_getIconForType(expense.type), color: AppTheme.accentOrange, size: 20),
        ),
        title: Text(expense.typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(DateFormat('dd MMM', 'fr').format(expense.date)),
        trailing: Text(
          '-${expense.amount.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  IconData _getIconForType(ExpenseType type) {
    switch (type) {
      case ExpenseType.salary: return Icons.people;
      case ExpenseType.cleaning: return Icons.cleaning_services;
      case ExpenseType.schoolSupplies: return Icons.school;
      case ExpenseType.rent: return Icons.home;
      case ExpenseType.utilities: return Icons.lightbulb;
      case ExpenseType.other: return Icons.category;
    }
  }
}
