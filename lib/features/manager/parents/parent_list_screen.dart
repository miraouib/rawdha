import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/level_helper.dart';
import '../../../models/parent_model.dart';
import '../../../models/student_model.dart';
import '../../../services/parent_service.dart';
import '../../../services/student_service.dart';
import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/school_service.dart'; // Import
import '../../../models/school_config_model.dart'; // Import
import 'parent_form_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class ParentListScreen extends ConsumerStatefulWidget {
  const ParentListScreen({super.key});

  @override
  ConsumerState<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends ConsumerState<ParentListScreen> {
  final ParentService _parentService = ParentService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('parent.management'.tr()),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'parent.search_parent'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<SchoolConfigModel>(
              stream: SchoolService().getSchoolConfig(ref.watch(currentRawdhaIdProvider) ?? ''),
              builder: (context, configSnapshot) {
                final schoolCode = configSnapshot.data?.schoolCode ?? '';
                
                return StreamBuilder<List<ParentModel>>(
                  stream: _parentService.getParents(ref.watch(currentRawdhaIdProvider) ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Filter list
                    final parents = snapshot.data!.where((parent) {
                      final query = _searchQuery;
                      return parent.firstName.toLowerCase().contains(query) ||
                          parent.lastName.toLowerCase().contains(query) ||
                          parent.phone.contains(query) ||
                          parent.familyCode.toLowerCase().contains(query) ||
                          parent.spouseName.toLowerCase().contains(query) ||
                          parent.spousePhone.contains(query);
                    }).toList()
                    ..sort((a, b) {
                       int cmp = a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
                       if (cmp != 0) return cmp;
                       return a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
                    });

                    if (parents.isEmpty) {
                      return Center(child: Text('common.search'.tr() + ': "$_searchQuery"'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: parents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final parent = parents[index];
                        return _ParentCard(parent: parent, schoolCode: schoolCode);
                      },
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed('parent_add');
        },
        label: Text('parent.add_parent'.tr()),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'parent.no_parent'.tr(),
            style: const TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }
}

class _ParentCard extends StatelessWidget {
  final ParentModel parent;
  final String schoolCode;

  const _ParentCard({required this.parent, required this.schoolCode});

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copié: $text')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
          child: const Icon(Icons.person, color: AppTheme.accentOrange),
        ),
        title: Text(
          '${parent.firstName} ${parent.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _copyToClipboard(context, parent.phone),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 14, color: AppTheme.textGray),
                  const SizedBox(width: 4),
                  Text(parent.phone, style: const TextStyle(decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 12, color: AppTheme.primaryBlue),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (schoolCode.isNotEmpty)
                  _CodeBadge(label: 'parent.school_label'.tr(), code: schoolCode, color: Colors.purple),
                _CodeBadge(label: 'parent.family_id_short'.tr(), code: parent.familyCode, color: Colors.blue),
              ],
            ),
          ],
        ),
        children: [
          if (parent.spouseName.isNotEmpty) ...[
             const Divider(),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('parent.spouse_name'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(parent.spouseName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (parent.spousePhone.isNotEmpty)
                      Flexible(
                        child: InkWell(
                          onTap: () => _copyToClipboard(context, parent.spousePhone),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.phone, size: 16, color: AppTheme.textGray),
                              const SizedBox(width: 4),
                              Flexible(child: Text(parent.spousePhone, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 12, color: AppTheme.primaryBlue),
                         ],
                       ),
                     ),
                   ),
                  ],
                ),
             ),
          ],
          const Divider(),
          _ParentChildrenList(parentId: parent.id),
          _ParentPaymentHistory(parentId: parent.id),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                  label: Text('parent.view_payments'.tr()),
                  onPressed: () {
                    context.pushNamed('parent_payment_history', extra: parent);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text('common.edit'.tr()),
                  onPressed: () {
                    context.pushNamed('parent_edit', extra: parent);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String label;
  final String code;
  final Color color;

  const _CodeBadge({required this.label, required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.code_copied'.tr())));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          '$label: $code',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ParentChildrenList extends ConsumerWidget {
  final String parentId;

  const _ParentChildrenList({required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentService = StudentService();
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';

    return StreamBuilder<List<StudentModel>>(
      stream: studentService.getStudentsByParentId(rawdhaId, parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); 
        }

        final students = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('parent.children_enrolled'.tr() + ' :', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
            ...students.map((student) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 12,
                backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                child: student.photoUrl == null ? Text(student.firstName[0], style: const TextStyle(fontSize: 10)) : null,
              ),
              title: Text('${student.firstName} ${student.lastName}'),
              subtitle: Text(student.levelId.isNotEmpty ? LevelHelper.getLevelName(student.levelId, context) : 'common.unknown'.tr()),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () {
                // Future: Navigate to student detail
              },
            )),
          ],
        );
      },
    );
  }
}

class _ParentPaymentHistory extends ConsumerWidget {
  final String parentId;

  const _ParentPaymentHistory({required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentService = PaymentService();
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    // Assuming start of school year is September of current/previous year
    // For simplicity, just show all payments covering the logical school year or just list all sorted by date.
    
    return StreamBuilder<List<PaymentModel>>(
      stream: paymentService.getPaymentsByParent(rawdhaId, parentId), // Ensure this method exists
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final payments = snapshot.data!;
        if (payments.isEmpty) return const SizedBox.shrink();

        final config = ref.watch(schoolConfigProvider).value;
        final startMonth = config?.paymentStartMonth ?? 9;
        
        // Calculate Start Date logic (same as other screens)
        final now = DateTime.now();
        final startYear = now.month >= startMonth ? now.year : now.year - 1;
        final startDate = DateTime(startYear, startMonth, 1);

        // Filter payments to hide those before start date
        final filteredPayments = payments.where((p) {
           // We compare year/month. 
           // If p.year < startYear, remove.
           // If p.year == startYear and p.month < startMonth, remove.
           // Or just compare dates. PaymentModel usually has a full date or month/year.
           // Let's use the date if available or construct it.
           final pDate = DateTime(p.year, p.month, 1);
           return !pDate.isBefore(startDate);
        }).toList();

        if (filteredPayments.isEmpty) return const SizedBox.shrink();

        // Sort by Date Descending
        filteredPayments.sort((a, b) => b.date.compareTo(a.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('parent.payment_history_short'.tr() + ' :', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filteredPayments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final p = filteredPayments[index];
                  Color color = Colors.grey;
                  if (p.status == PaymentStatus.paid) color = Colors.green;
                  else if (p.status == PaymentStatus.partial) color = Colors.orange;
                  else if (p.status == PaymentStatus.unpaid) color = Colors.red;

                  return Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('MMM', 'fr').format(p.date).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        Text('${p.amount.toInt()}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
