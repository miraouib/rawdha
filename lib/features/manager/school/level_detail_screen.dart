import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_level_model.dart';
import '../../../models/school_class_model.dart';
import '../../../services/school_service.dart';
import 'class_form_dialog.dart';

/// Détails d'un niveau : Liste des classes
class LevelDetailScreen extends StatelessWidget {
  final SchoolLevelModel level;

  const LevelDetailScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final schoolService = SchoolService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('levels.${level.id}'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClassDialog(context, level.id),
          ),
        ],
      ),
      body: StreamBuilder<List<SchoolClassModel>>(
        stream: schoolService.getClassesForLevel(level.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final classes = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ClassCard(classModel: classes[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'school.no_classes'.tr(),
            style: TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddClassDialog(context, level.id),
            icon: const Icon(Icons.add),
            label: Text('school.add_first_class'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, String levelId) {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(levelId: levelId),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final SchoolClassModel classModel;

  const _ClassCard({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentPurple.withOpacity(0.1),
          child: Icon(Icons.school, color: AppTheme.accentPurple),
        ),
        title: Text(
          classModel.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Capacité: ${classModel.capacity} élèves'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Naviguer vers la liste des élèves de cette classe
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Liste des élèves à venir...')),
          );
        },
        onLongPress: () {
          // TODO: Modifier/Supprimer la classe
          showDialog(
            context: context,
            builder: (context) => ClassFormDialog(
              levelId: classModel.levelId,
              schoolClass: classModel,
            ),
          );
        },
      ),
    );
  }
}
