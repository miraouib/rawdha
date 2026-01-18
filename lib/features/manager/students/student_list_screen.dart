import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/level_helper.dart';
import '../../../models/student_model.dart';
import '../../../models/school_level_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/student_service.dart';
import '../../../services/school_service.dart';
import '../../../services/parent_service.dart';
import '../../../core/widgets/manager_footer.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final StudentService _studentService = StudentService();
  final SchoolService _schoolService = SchoolService();
  
  String _searchQuery = '';
  String? _selectedLevelId;
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
        title: const Text('Gestion des Élèves'),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un élève',
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
                const SizedBox(height: 12),
                StreamBuilder<List<SchoolLevelModel>>(
                  stream: _schoolService.getLevels(ref.watch(currentRawdhaIdProvider) ?? ''),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final levels = snapshot.data!;
                    return SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: levels.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return FilterChip(
                              label: const Text('Tous'),
                              selected: _selectedLevelId == null,
                              onSelected: (v) => setState(() => _selectedLevelId = null),
                            );
                          }
                          final level = levels[index - 1];
                          final isArabic = context.locale.languageCode == 'ar';
                          final levelName = isArabic ? level.nameAr : level.nameFr;
                          return FilterChip(
                            label: Text(levelName.split(' ').first), // Short name
                            selected: _selectedLevelId == level.id,
                            onSelected: (v) => setState(() => _selectedLevelId = v ? level.id : null),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<StudentModel>>(
        stream: _studentService.getStudents(ref.watch(currentRawdhaIdProvider) ?? ''),
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
            final matchesName = s.firstName.toLowerCase().contains(_searchQuery) || 
                              s.lastName.toLowerCase().contains(_searchQuery);
            final matchesLevel = _selectedLevelId == null || s.levelId == _selectedLevelId;
            return matchesName && matchesLevel;
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = students[index];
              return _StudentCard(student: student);
                },
              );
            },
          ),
        ), // Expanded
       ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed('student_add');
        },
        label: const Text('Nouvel Élève'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryBlue,
      ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text(
            'Aucun élève enregistré',
            style: TextStyle(fontSize: 18, color: AppTheme.textGray),
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
            Text(student.levelId.isEmpty ? 'Niveau non défini' : LevelHelper.getLevelName(student.levelId, context)),
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

