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
  
  late Stream<List<SchoolLevelModel>> _levelsStream;
  late Stream<List<StudentModel>> _studentsStream;
  
  String _searchQuery = '';
  String? _selectedLevelId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _levelsStream = _schoolService.getLevels(rawdhaId);
    _studentsStream = _studentService.getStudents(rawdhaId);
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
        title: Text('student.management_title'.tr()),
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
                    hintText: 'student.search_hint'.tr(),
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
                  stream: _levelsStream,
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
                              label: Text('student.all'.tr()),
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
        stream: _studentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${'common.error'.tr()}: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final students = snapshot.data!.where((s) {
            final matchesName = s.firstName.toLowerCase().contains(_searchQuery) || 
                              s.lastName.toLowerCase().contains(_searchQuery);
            
            bool matchesLevel = _selectedLevelId == null;
            if (!matchesLevel) {
              final studentBaseLevelId = s.levelId.split('_').last;
              final selectedBaseLevelId = _selectedLevelId!.split('_').last;
              matchesLevel = studentBaseLevelId == selectedBaseLevelId;
            }
            
            return matchesName && matchesLevel;
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = students[index];
              return _StudentCard(
                student: student,
                onDelete: () => _deleteStudent(student),
              );
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
        label: Text('student.new_student'.tr()),
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
          Text(
            'student.empty_state'.tr(),
            style: const TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Text('student.confirm_delete'.tr()), // Using specific key, need to add it or fallback
        // If key missing, I'll add it to translations next step or use generic.
        // Let's assume I'll add it or use a generic "Are you sure?"
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final rawdhaId = ref.read(currentRawdhaIdProvider);
        if (rawdhaId == null) return;
        
        // We need parent IDs to unlink
        await _studentService.deleteStudent(rawdhaId, student.studentId, student.parentIds);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('common.success'.tr()), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _StudentCard extends ConsumerWidget {
  final StudentModel student;
  final VoidCallback onDelete;

  const _StudentCard({required this.student, required this.onDelete});

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
            Text(student.levelId.isEmpty ? 'student.level_not_defined'.tr() : LevelHelper.getLevelName(student.levelId, context)),
            if (student.parentIds.isNotEmpty)
              FutureBuilder<ParentModel?>(
                future: ParentService().getParentById(rawdhaId, student.parentIds.first),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final parent = snapshot.data!;
                    return Text(
                      'student.resp_hint'.tr(args: [parent.firstName, parent.phone]),
                      style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          context.pushNamed('student_detail', extra: student);
        },
      ),
    );
  }
}

