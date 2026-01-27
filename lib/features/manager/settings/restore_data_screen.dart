import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../models/parent_model.dart';
import '../../../models/student_model.dart';
import '../../../services/school_service.dart';
import '../../../services/parent_service.dart';
import '../../../services/student_service.dart';
import '../../../models/school_level_model.dart';


class RestoreDataScreen extends ConsumerStatefulWidget {
  const RestoreDataScreen({super.key});

  @override
  ConsumerState<RestoreDataScreen> createState() => _RestoreDataScreenState();
}

class _RestoreDataScreenState extends ConsumerState<RestoreDataScreen> {
  final ParentService _parentService = ParentService();
  final StudentService _studentService = StudentService();
  final SchoolService _schoolService = SchoolService();
  
  String _searchQuery = '';
  final Map<String, String> _selectedLevels = {}; // studentId -> levelId

  List<ParentModel> _archivedParents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedParents();
  }

  Future<void> _loadArchivedParents() async {
    setState(() => _isLoading = true);
    try {
      final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
      final parents = await _parentService.getArchivedParents(rawdhaId);
      if (mounted) {
        setState(() {
          _archivedParents = parents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('school.restore.title'.tr()),
        actions: [
          if (_archivedParents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'school.restore.delete_all_tooltip'.tr(),
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'school.restore.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Builder(
                  builder: (context) {
                    final filtered = _archivedParents.where((p) {
                      if (_searchQuery.isEmpty) return true;
                      final name = '${p.firstName} ${p.lastName}'.toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('school.restore.no_results'.tr(), style: const TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final parent = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.history, color: Colors.white),
                            ),
                            title: Text('${parent.firstName} ${parent.lastName}'),
                            subtitle: Text('${parent.studentIds.length} ${'school.restore.archived_children'.tr()}'),
                            children: [
                              _buildRestoreForm(rawdhaId, parent),
                            ],
                          ),
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

  Widget _buildRestoreForm(String rawdhaId, ParentModel parent) {
    return _RestoreParentForm(
      rawdhaId: rawdhaId, 
      parent: parent, 
      onRestore: _restoreParent,
      onDeletePermanently: _deleteParentPermanently,
    );
  }

  Future<void> _restoreParent(ParentModel parent, List<StudentModel> students) async {
    try {
      // Build map of StudentID -> NewLevelID
      final updates = <String, String>{};
      for (var s in students) {
        updates[s.studentId] = _selectedLevels[s.studentId] ?? s.levelId;
      }

      await _schoolService.restoreParent(parent.id, updates);
      
      // Update local state to remove restored parent
      if (mounted) {
        setState(() {
          _archivedParents.removeWhere((p) => p.id == parent.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('school.restore.success_restore'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'common.error'.tr()}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('school.restore.delete_all_confirm_title'.tr()),
        content: Text(
          'school.restore.delete_all_confirm_msg'.tr(),
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('school.restore.delete_all_btn'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
        await _parentService.deleteAllArchivedParents(rawdhaId);
        setState(() {
          _archivedParents.clear();
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('school.restore.all_deleted'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'common.error'.tr()}: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteParentPermanently(ParentModel parent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('school.restore.delete_all_confirm_title'.tr()),
        content: Text(
          'school.restore.delete_individual_msg'.tr(args: [parent.firstName, parent.lastName]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
        await _parentService.deleteParentWithStudents(rawdhaId, parent.id);
        
        if (mounted) {
          setState(() {
            _archivedParents.removeWhere((p) => p.id == parent.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('school.restore.parent_deleted'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'common.error'.tr()}: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _RestoreParentForm extends ConsumerStatefulWidget {
  final String rawdhaId;
  final ParentModel parent;
  final Function(ParentModel, List<StudentModel>) onRestore;
  final Function(ParentModel) onDeletePermanently; // Added callback

  const _RestoreParentForm({
    required this.rawdhaId,
    required this.parent,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  @override
  ConsumerState<_RestoreParentForm> createState() => _RestoreParentFormState();
}

class _RestoreParentFormState extends ConsumerState<_RestoreParentForm> {
  late Stream<List<StudentModel>> _studentsStream;
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    _studentsStream = _studentService.getStudentsByParentId(widget.rawdhaId, widget.parent.id, includeDeleted: true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentModel>>(
      stream: _studentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
        
        final students = snapshot.data!;
        // Assuming we want to show existing students or a message if none
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (students.isNotEmpty) ...[
                 Text("school.restore.update_levels".tr(), 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 ...students.map((student) {
                   return _StudentLevelSelector(rawdhaId: widget.rawdhaId, student: student);
                 }),
              ] else ...[
                 Text("school.restore.no_children_linked".tr(), style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: Text('school.restore.restore_btn'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => widget.onRestore(widget.parent, students),
                    ),
                  ),
                  const SizedBox(width: 8),
                   Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => widget.onDeletePermanently(widget.parent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentLevelSelector extends ConsumerStatefulWidget {
  final String rawdhaId;
  final StudentModel student;

  const _StudentLevelSelector({required this.rawdhaId, required this.student});

  @override
  ConsumerState<_StudentLevelSelector> createState() => _StudentLevelSelectorState();
}

class _StudentLevelSelectorState extends ConsumerState<_StudentLevelSelector> {
  late Stream<List<SchoolLevelModel>> _levelsStream;
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    _levelsStream = _schoolService.getLevels(widget.rawdhaId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolLevelModel>>(
      stream: _levelsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final levels = snapshot.data!;
        
        final parent = context.findAncestorStateOfType<_RestoreDataScreenState>();
        if (parent == null) return const SizedBox();

        // Default to current selection or student's old level
        final currentSelection = parent._selectedLevels[widget.student.studentId] ?? widget.student.levelId;

        // Ensure selection is valid (exists in list), otherwise default to first
        final validSelection = levels.any((l) => l.id == currentSelection) 
            ? currentSelection 
            : (levels.isNotEmpty ? levels.first.id : '');

        if (validSelection != parent._selectedLevels[widget.student.studentId]) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted && parent.mounted) {
                 parent.setState(() => parent._selectedLevels[widget.student.studentId] = validSelection);
               }
             });
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${widget.student.firstName} ${widget.student.lastName}'),
          trailing: DropdownButton<String>(
            value: validSelection,
            items: levels.map((l) => DropdownMenuItem(
              value: l.id,
              child: Text(
                context.locale.toString() == 'ar' ? l.nameAr : l.nameFr,
                style: const TextStyle(fontSize: 14),
              ),
            )).toList(),
            onChanged: (val) {
              if (val != null) {
                parent.setState(() => parent._selectedLevels[widget.student.studentId] = val);
              }
            },
          ),
        );
      },
    );
  }
}
