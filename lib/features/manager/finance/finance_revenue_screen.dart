import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/payment_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/parent_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class FinanceRevenueScreen extends ConsumerStatefulWidget {
  const FinanceRevenueScreen({super.key});

  @override
  ConsumerState<FinanceRevenueScreen> createState() => _FinanceRevenueScreenState();
}

class _FinanceRevenueScreenState extends ConsumerState<FinanceRevenueScreen> {
  DateTime _currentMonth = DateTime.now();
  final PaymentService _paymentService = PaymentService();
  final ParentService _parentService = ParentService();
  

  bool _filterOrange = true;
  bool _filterGreen = true;
  String _revenueSearchQuery = '';

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
        title: Text('finance.revenue'.tr()),
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

              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              stream: _paymentService.getPaymentsByMonth(ref.watch(currentRawdhaIdProvider) ?? '', _currentMonth.month, _currentMonth.year),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('${"common.error".tr()}: ${snapshot.error}'));
                }

                final allPayments = snapshot.data ?? [];
                
                return StreamBuilder<List<ParentModel>>(
                  stream: _parentService.getParents(ref.watch(currentRawdhaIdProvider) ?? ''),
                  builder: (context, parentSnapshot) {
                    if (!parentSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final parents = parentSnapshot.data!;
                    final parentMap = {for (var p in parents) p.id: p};
                    
                    final filteredPayments = allPayments.where((p) {
                      if (p.status == PaymentStatus.paid && !_filterGreen) return false;
                      if (p.status == PaymentStatus.partial && !_filterOrange) return false;
                      if (p.status == PaymentStatus.unpaid) return false;
                      
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
                           const SizedBox(height: 24),
                           ...filteredPayments.map((p) => _PaymentItem(
                             payment: p, 
                             parentMap: parentMap,
                             onDelete: () => _confirmDeletePayment(context, p),
                           )),
                           const SizedBox(height: 80),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('revenue_add'),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
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

  Future<void> _confirmDeletePayment(BuildContext context, PaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Text('finance.confirm_delete_payment'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final rawdhaId = ref.read(currentRawdhaIdProvider);
      if (rawdhaId != null) {
        await _paymentService.deletePayment(rawdhaId, payment.id);
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('finance.payment_deleted'.tr())));
        }
      }
    }
  }
}

class _PaymentItem extends StatelessWidget {
  final PaymentModel payment;
  final Map<String, ParentModel> parentMap;
  final VoidCallback onDelete;

  const _PaymentItem({required this.payment, required this.parentMap, required this.onDelete});

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
              icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
