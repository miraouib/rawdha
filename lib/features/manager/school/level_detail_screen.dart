import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_level_model.dart';
import '../../../models/student_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/student_service.dart';
import '../../../services/parent_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

/// Détails d'un niveau : Liste des élèves
class LevelDetailScreen extends ConsumerStatefulWidget {
  final SchoolLevelModel level;

  const LevelDetailScreen({super.key, required this.level});

  @override
  ConsumerState<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends ConsumerState<LevelDetailScreen> {
  final StudentService _studentService = StudentService();
  late Stream<List<StudentModel>> _studentsStream;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _studentsStream = _studentService.getStudentsByLevel(rawdhaId, widget.level.id);
  }

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
        title: Text('${Localizations.localeOf(context).languageCode == 'ar' ? widget.level.nameAr : widget.level.nameFr} - ${'student.students'.tr()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
               context.pushNamed('student_add');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'student.search_student'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    })
                  : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StudentModel>>(
              stream: _studentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                   return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context);
                }

                final students = snapshot.data!.where((s) {
                  return s.firstName.toLowerCase().contains(_searchQuery) || 
                         s.lastName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (students.isEmpty) {
                   return Center(child: Text('common.no_results'.tr()));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: students.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _StudentCard(student: student);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'school.no_classes'.tr(),
            style: TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
               context.pushNamed('student_add');
            },
            icon: const Icon(Icons.add),
            label: Text('student.add_student'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends ConsumerWidget {
  final StudentModel student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
          child: student.photoUrl == null ? Text(student.firstName[0]) : null,
        ),
        title: Text(
          '${student.firstName} ${student.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (student.parentIds.isNotEmpty)
              FutureBuilder<ParentModel?>(
                future: ParentService().getParentById(rawdhaId, student.parentIds.first),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final parent = snapshot.data!;
                    return Text(
                      'Resp: ${parent.firstName} - ${parent.phone}',
                      style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.pushNamed('student_detail', extra: student);
        },
      ),
    );
  }
}

