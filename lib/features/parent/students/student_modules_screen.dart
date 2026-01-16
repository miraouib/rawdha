import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/student_model.dart';
import '../../../models/module_model.dart';
import '../../../services/module_service.dart';
import '../widgets/module_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class StudentModulesScreen extends ConsumerWidget {
  final StudentModel student;
  const StudentModulesScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? student.rawdhaId;
    final moduleService = ModuleService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('${student.firstName} - ${'module.management_title'.tr()}'),
      ),
      body: StreamBuilder<List<ModuleModel>>(
        stream: moduleService.getModulesForLevel(rawdhaId, student.levelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allModules = snapshot.data ?? [];
          final activeModule = allModules.where((m) => m.isCurrentlyActive).firstOrNull;
          
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              // Bouton Signaler Absence - NOUVEAU
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pushNamed('parent_report_absence', extra: student);
                  },
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  label: Text('absence.report_title'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Module Actuel
              if (activeModule != null) ...[
                _buildSectionTitle('module.active_label'.tr(), Icons.star, Colors.orange),
                const SizedBox(height: 12),
                ModuleCard(module: activeModule),
                const SizedBox(height: 32),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, size: 48, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('module.no_active_module'.tr(), style: const TextStyle(color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                ),
              ],

              // Bouton Historique
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.pushNamed('student_history', extra: student);
                    },
                    icon: const Icon(Icons.history),
                    label: Text('module.view_history'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
