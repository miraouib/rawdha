import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/payment_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/parent_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class FinanceUnpaidScreen extends ConsumerStatefulWidget {
  const FinanceUnpaidScreen({super.key});

  @override
  ConsumerState<FinanceUnpaidScreen> createState() => _FinanceUnpaidScreenState();
}

class _FinanceUnpaidScreenState extends ConsumerState<FinanceUnpaidScreen> {
  DateTime _currentMonth = DateTime.now();
  final PaymentService _paymentService = PaymentService();
  final ParentService _parentService = ParentService();
  String _revenueSearchQuery = '';

  void _changeMonth(int increment) {
    final config = ref.read(schoolConfigProvider).value;
    final startMonth = config?.paymentStartMonth ?? 9;
    
    final now = DateTime.now();
    final startYear = now.month >= startMonth ? now.year : now.year - 1;
    final startDate = DateTime(startYear, startMonth, 1);

    final newMonth = DateTime(_currentMonth.year, _currentMonth.month + increment);
    
    if (increment < 0 && newMonth.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('finance.limit_reached'.tr())),
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
        title: Text('finance.unpaid_title'.tr()),
      ),
      body: Column(
        children: [
          // Month Selector (Already localized to French)
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
          
          Expanded(
            child: StreamBuilder<List<ParentModel>>(
              stream: _parentService.getParents(ref.watch(currentRawdhaIdProvider) ?? ''),
              builder: (context, parentSnapshot) {
                if (!parentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final allParents = parentSnapshot.data!;

                return StreamBuilder<List<PaymentModel>>(
                  stream: _paymentService.getPaymentsByMonth(ref.watch(currentRawdhaIdProvider) ?? '', _currentMonth.month, _currentMonth.year),
                  builder: (context, paymentSnapshot) {
                    if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payments = paymentSnapshot.data ?? [];
                    final paidParentIds = payments.map((p) => p.parentId).toSet();

                    final unpaidParents = allParents.where((p) {
                      if (paidParentIds.contains(p.id)) return false;
                      if (_revenueSearchQuery.isNotEmpty) {
                        final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
                        if (!fullName.contains(_revenueSearchQuery)) return false;
                      }
                      return true;
                    }).toList();

                    if (unpaidParents.isEmpty) {
                      return Center(child: Text('finance.all_paid'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: unpaidParents.length,
                      itemBuilder: (context, index) {
                        final parent = unpaidParents[index];
                        final monthlyFee = parent.monthlyFee ?? 0.0;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              child: const Icon(Icons.warning, color: Colors.red),
                            ),
                            title: Text('${parent.firstName} ${parent.lastName}'),
                            subtitle: Text('${"finance.expected_amount_short_label".tr()}: ${monthlyFee > 0 ? monthlyFee : "??"} ${"finance.currency".tr()}'),
                            trailing: ElevatedButton(
                              child: Text('finance.pay_button'.tr()),
                              onPressed: () {
                                context.pushNamed('revenue_add', extra: parent.id);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
