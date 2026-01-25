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

import '../../../core/widgets/parent_footer.dart';

class StudentModulesScreen extends ConsumerStatefulWidget {
  final StudentModel student;
  const StudentModulesScreen({super.key, required this.student});

  @override
  ConsumerState<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends ConsumerState<StudentModulesScreen> {
  late Stream<List<ModuleModel>> _modulesStream;
  final ModuleService _moduleService = ModuleService();

  @override
  void initState() {
    super.initState();
    // On utilise directement le rawdhaId de l'élève pour garantir la correspondance
    _modulesStream = _moduleService.getModulesForLevel(widget.student.rawdhaId, widget.student.levelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      bottomNavigationBar: const ParentFooter(),
      appBar: AppBar(
        title: Text('${widget.student.firstName} - ${'module.management_title'.tr()}'),
      ),
      body: StreamBuilder<List<ModuleModel>>(
        stream: _modulesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('common.error'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allModules = snapshot.data ?? [];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final activeModule = allModules.where((m) => m.isCurrentlyActive).firstOrNull;
          
          // Past modules: Modules that ended before today
          final pastModules = allModules.where((m) {
            final end = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);
            return end.isBefore(today);
          }).toList().reversed.toList();
          
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              // Bouton Signaler Absence
              _buildAbsenceButton(context),
              const SizedBox(height: 24),

              // SECTION : MODULE ACTUEL
              _buildSectionTitle('module.active_label'.tr(), Icons.star, Colors.orange),
              const SizedBox(height: 12),
              if (activeModule != null)
                ModuleCard(module: activeModule)
              else
                _buildEmptyActiveState(),

              const SizedBox(height: 32),

              // SECTION : HISTORIQUE (Anciens modules uniquement)
              if (pastModules.isNotEmpty) ...[
                _buildSectionTitle('module.view_history'.tr(), Icons.history, AppTheme.primaryBlue),
                const SizedBox(height: 12),
                ...pastModules.map((m) => _buildHistoryItem(context, m)).toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAbsenceButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.pushNamed('parent_report_absence', extra: widget.student);
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
    );
  }

  Widget _buildEmptyActiveState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 40, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            'module.no_active_module'.tr(),
            style: const TextStyle(color: AppTheme.textGray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ModuleModel module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.book, color: AppTheme.primaryBlue, size: 20),
        ),
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM').format(module.startDate)} - ${DateFormat('dd/MM').format(module.endDate)}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
        onTap: () => _showModuleDetails(context, module),
      ),
    );
  }

  void _showModuleDetails(BuildContext context, ModuleModel module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Drag Handle & Close Button Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Spacer for centering handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textGray),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      ModuleCard(module: module),
                      const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
