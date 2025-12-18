import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/parent_service.dart';
import '../../../services/payment_service.dart';

class RevenueFormScreen extends StatefulWidget {
  final String? parentId;

  const RevenueFormScreen({super.key, this.parentId});

  @override
  State<RevenueFormScreen> createState() => _RevenueFormScreenState();
}

class _RevenueFormScreenState extends State<RevenueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedParentId;
  double _expectedAmount = 0.0;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String _parentSearchQuery = '';
  
  final PaymentService _paymentService = PaymentService();
  final ParentService _parentService = ParentService();

  @override
  void initState() {
    super.initState();
    if (widget.parentId != null) {
      _selectedParentId = widget.parentId;
      _calculateExpected();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _calculateExpected() async {
    if (_selectedParentId != null) {
      final amount = await _paymentService.calculateExpectedAmount(_selectedParentId!);
      setState(() {
        _expectedAmount = amount;
        if (_amountController.text.isEmpty) {
           _amountController.text = amount.toStringAsFixed(0);
        }
      });
    }
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    int tempYear = _selectedYear;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => tempYear--),
                ),
                Text('$tempYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => tempYear++),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              height: 300,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final isSelected = month == _selectedMonth && tempYear == _selectedYear;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                         _selectedYear = tempYear;
                         _selectedMonth = month;
                         _selectedDate = DateTime(tempYear, month, 1);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM', 'fr').format(DateTime(2022, month)),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor() {
    final currentAmount = double.tryParse(_amountController.text) ?? 0;
    if (currentAmount >= _expectedAmount && _expectedAmount > 0) return Colors.green;
    if (currentAmount > 0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('finance.select_parent'.tr())));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = PaymentModel(
        id: '',
        parentId: _selectedParentId!,
        amount: double.parse(_amountController.text),
        expectedAmount: _expectedAmount,
        date: _selectedDate,
        month: _selectedMonth,
        year: _selectedYear,
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(payment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('finance.payment_saved'.tr())));
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
    final statusColor = _getStatusColor();

    return Scaffold(
      appBar: AppBar(title: Text('finance.record_revenue'.tr())),
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
                      // Search Field
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'finance.search_parent'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) {
                          setState(() => _parentSearchQuery = value.toLowerCase());
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Parent Selector
                      StreamBuilder<List<ParentModel>>(
                        stream: _parentService.getParents(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          
                          final allParents = snapshot.data!;
                          final filteredParents = allParents.where((p) {
                            if (_parentSearchQuery.isEmpty) return true;
                            final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
                            return fullName.contains(_parentSearchQuery) || 
                                   p.familyCode.toLowerCase().contains(_parentSearchQuery);
                          }).toList();
                          
                          filteredParents.sort((a, b) => 
                            '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}')
                          );
                          
                          return DropdownButtonFormField<String>(
                            value: _selectedParentId,
                            decoration: InputDecoration(
                              labelText: '${"finance.parent".tr()} (${filteredParents.length} ${"finance.results".tr()})',
                              prefixIcon: const Icon(Icons.person),
                            ),
                            items: filteredParents.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.firstName} ${p.lastName} (${p.familyCode})'),
                            )).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedParentId = v;
                                _amountController.clear();
                              });
                              _calculateExpected();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Expected Amount
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('finance.expected_amount'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_expectedAmount.toStringAsFixed(2)} ${"finance.currency".tr()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${"finance.amount_paid".tr()} (${"finance.currency".tr()})',
                          prefixIcon: const Icon(Icons.attach_money),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: statusColor)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: statusColor, width: 2)),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'finance.required'.tr();
                          if (double.tryParse(v) == null) return 'finance.invalid'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                           statusColor == Colors.green ? 'finance.status_paid'.tr() : 
                           statusColor == Colors.orange ? 'finance.status_partial'.tr() : 'finance.status_unpaid'.tr(),
                           style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Date
                        InkWell(
                          onTap: () => _showMonthPicker(context),
                          child: InputDecorator(
                            decoration: InputDecoration(labelText: 'Mois Concerné', prefixIcon: const Icon(Icons.calendar_month)),
                            child: Text(DateFormat('MM-yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Note
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(labelText: 'finance.note_optional'.tr(), prefixIcon: const Icon(Icons.note)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('finance.add_revenue'.tr(), style: const TextStyle(fontSize: 18, color: Colors.white)),
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
