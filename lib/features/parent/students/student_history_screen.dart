import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/student_model.dart';
import '../../../models/module_model.dart';
import '../../../services/module_service.dart';
import '../widgets/module_card.dart';
import '../../../core/helpers/date_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

import '../../../core/widgets/parent_footer.dart';

class StudentHistoryScreen extends ConsumerWidget {
  final StudentModel student;
  const StudentHistoryScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? student.rawdhaId;
    final moduleService = ModuleService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      bottomNavigationBar: const ParentFooter(),
      appBar: AppBar(
        title: Text('module.history_title'.tr()),
      ),
      body: StreamBuilder<List<ModuleModel>>(
        stream: moduleService.getModulesForLevel(rawdhaId, student.levelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allModules = snapshot.data ?? [];
          final pastModules = allModules
              .where((m) => !m.isCurrentlyActive && m.endDate.isBefore(DateTime.now()))
              .toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate)); // Most recent first

          if (pastModules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.history, size: 60, color: AppTheme.textLight),
                   const SizedBox(height: 16),
                   Text('module.no_history'.tr(), style: const TextStyle(color: AppTheme.textGray)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pastModules.length,
            itemBuilder: (context, index) {
              final module = pastModules[index];
              return _HistoryCard(module: module);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ModuleModel module;
  const _HistoryCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.book, color: AppTheme.primaryBlue),
        ),
        title: Text(module.getTitle(context.locale.languageCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(
          DateHelper.formatMonthYear(context, module.startDate).toUpperCase(),
          style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showDetails(context);
        },
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ModuleCard(module: module),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
