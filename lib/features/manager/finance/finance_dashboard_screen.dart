import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/expense_model.dart';
import '../../../services/finance_service.dart';
import 'expense_form_screen.dart';
import '../../../models/payment_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/parent_service.dart';
import 'revenue_form_screen.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentMonth = DateTime.now();
  final FinanceService _financeService = FinanceService();
  final PaymentService _paymentService = PaymentService();
  final ParentService _parentService = ParentService();
  
  // Filters for Revenue
  bool _filterRed = true;
  bool _filterOrange = true;
  bool _filterGreen = true;
  String _revenueSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + increment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('finance.title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'finance.expenses'.tr()),
            Tab(text: 'finance.revenue'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildRevenueTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpenseFormScreen()),
            );
          } else {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RevenueFormScreen()),
            );
          }
        },
        label: Text(_tabController.index == 0 ? 'finance.new_expense'.tr() : 'finance.new_payment'.tr()),
        icon: const Icon(Icons.add),
        backgroundColor: _tabController.index == 0 ? AppTheme.accentOrange : AppTheme.primaryBlue,
      ),
    );
  }
  
  // ... _buildExpensesTab exists ...

  Widget _buildRevenueTab() {
    return Column(
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
                DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth).toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'finance.search_parent'.tr(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) => setState(() => _revenueSearchQuery = value.toLowerCase()),
          ),
        ),

        // Filters with Icons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterChip(
                avatar: Icon(Icons.check_circle, color: _filterGreen ? Colors.green : Colors.grey, size: 20),
                label: const Text(''),
                selected: _filterGreen,
                onSelected: (v) => setState(() => _filterGreen = v),
                selectedColor: Colors.green.withOpacity(0.2),
                backgroundColor: Colors.grey.shade100,
              ),
              FilterChip(
                avatar: Icon(Icons.warning, color: _filterOrange ? Colors.orange : Colors.grey, size: 20),
                label: const Text(''),
                selected: _filterOrange,
                onSelected: (v) => setState(() => _filterOrange = v),
                selectedColor: Colors.orange.withOpacity(0.2),
                backgroundColor: Colors.grey.shade100,
              ),
              FilterChip(
                avatar: Icon(Icons.error, color: _filterRed ? Colors.red : Colors.grey, size: 20),
                label: const Text(''),
                selected: _filterRed,
                onSelected: (v) => setState(() => _filterRed = v),
                selectedColor: Colors.red.withOpacity(0.2),
                backgroundColor: Colors.grey.shade100,
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<PaymentModel>>(
            stream: _paymentService.getPaymentsByMonth(_currentMonth.month, _currentMonth.year),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('${"common.error".tr()}: ${snapshot.error}'));
              }

              final allPayments = snapshot.data ?? [];
              
              // Filter logic with parent name search
              return StreamBuilder<List<ParentModel>>(
                stream: _parentService.getParents(),
                builder: (context, parentSnapshot) {
                  if (!parentSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final parents = parentSnapshot.data!;
                  final parentMap = {for (var p in parents) p.id: p};
                  
                  final filteredPayments = allPayments.where((p) {
                    // Status filter
                    if (p.status == PaymentStatus.paid && !_filterGreen) return false;
                    if (p.status == PaymentStatus.partial && !_filterOrange) return false;
                    if (p.status == PaymentStatus.unpaid && !_filterRed) return false;
                    
                    // Search filter
                    if (_revenueSearchQuery.isNotEmpty) {
                      final parent = parentMap[p.parentId];
                      if (parent == null) return false;
                      final fullName = '${parent.firstName} ${parent.lastName}'.toLowerCase();
                      if (!fullName.contains(_revenueSearchQuery)) return false;
                    }
                    
                    return true;
                  }).toList();

                  final totalRevenue = filteredPayments.fold(0.0, (sum, item) => sum + item.amount);

                  if (filteredPayments.isEmpty) {
                     return _buildEmptyStateRevenue();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTotalCardInternal(totalRevenue, 'finance.revenue'.tr(), AppTheme.primaryBlue, AppTheme.accentTeal),
                        const SizedBox(height: 24),
                         ...filteredPayments.map((p) => _PaymentItem(payment: p, parentMap: parentMap)),
                         const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateRevenue() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monetization_on_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('finance.no_revenue'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTotalCardInternal(double total, String label, Color c1, Color c2) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.gradientCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${"common.total".tr()} $label', style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 4),
              const Icon(Icons.trending_up, color: Colors.white, size: 24),
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

  Widget _buildExpensesTab() {
    return Column(
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
                DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth).toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<List<ExpenseModel>>(
            stream: _financeService.getExpensesByMonth(_currentMonth.month, _currentMonth.year),
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

              // Group by Type
              final expensesByType = <ExpenseType, double>{};
              for (var e in expenses) {
                expensesByType[e.type] = (expensesByType[e.type] ?? 0) + e.amount;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Total Card
                    _buildTotalCard(totalAmount),
                    const SizedBox(height: 16),
                    
                    // Breakdown by Type
                    _buildBreakdown(expensesByType),
                    const SizedBox(height: 24),
                    
                    // Recent List
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('finance.month_details'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ...expenses.map((e) => _ExpenseItem(expense: e)),
                    
                    // Margin for FAB
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
                '${total.toStringAsFixed(2)} ${"finance.currency".tr()}', // Replace currency symbol if needed
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
            final typeLabel = ExpenseModel(
              id: '', 
              type: entry.key, 
              amount: 0, 
              date: DateTime.now(), 
              createdAt: DateTime.now()
            ).typeLabel;
            
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
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseItem({required this.expense});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('finance.confirm_delete'.tr()),
        content: Text('finance.confirm_delete_expense'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FinanceService().deleteExpense(expense.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('finance.expense_deleted'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

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
        subtitle: Text(DateFormat('dd MMM').format(expense.date) + (expense.description.isNotEmpty ? ' - ${expense.description}' : '')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.grey,
              onPressed: () => _confirmDelete(context),
            ),
          ],
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

class _PaymentItem extends StatelessWidget {
  final PaymentModel payment;
  final Map<String, ParentModel> parentMap;

  const _PaymentItem({required this.payment, required this.parentMap});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('finance.confirm_delete'.tr()),
        content: Text('finance.confirm_delete_payment'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await PaymentService().deletePayment(payment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paiement supprimé')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (payment.status) {
      case PaymentStatus.paid:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.partial:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case PaymentStatus.unpaid:
        color = Colors.red;
        icon = Icons.error;
        break;
    }

    final parent = parentMap[payment.parentId];
    final parentName = parent != null ? '${parent.firstName} ${parent.lastName}' : 'finance.unknown_parent'.tr();

    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(parentName, style: const TextStyle(fontWeight: FontWeight.bold)), 
        subtitle: Text('${"finance.expected_amount".tr()}: ${payment.expectedAmount.toStringAsFixed(0)} ${"finance.currency".tr()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${payment.amount.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red.shade400,
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
