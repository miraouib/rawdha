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

  @override
  Widget build(BuildContext context) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Restaurer Données'),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un parent archivé...',
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
            child: StreamBuilder<List<ParentModel>>(
              stream: _parentService.getArchivedParents(rawdhaId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final parents = snapshot.data!;
                final filtered = parents.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  final name = '${p.firstName} ${p.lastName}'.toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Aucun parent archivé trouvé', style: TextStyle(color: Colors.grey)),
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
                        subtitle: Text('${parent.studentIds.length} enfant(s) archivés'),
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
    return StreamBuilder<List<StudentModel>>(
      // Important: fetch deleted students too
      stream: _studentService.getStudentsByParentId(rawdhaId, parent.id, includeDeleted: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
        
        final students = snapshot.data!;
        if (students.isEmpty) return const Text("Aucun enfant trouvé.");

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Mettre à jour les niveaux pour la nouvelle année :", 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              ...students.map((student) {
                return _buildStudentLevelSelector(rawdhaId, student);
              }),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restaurer ce parent et ses enfants'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _restoreParent(parent, students),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentLevelSelector(String rawdhaId, StudentModel student) {
    return StreamBuilder(
      stream: _schoolService.getLevels(rawdhaId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final levels = snapshot.data!;
        
        // Default to current selection or student's old level
        final currentSelection = _selectedLevels[student.studentId] ?? student.levelId;

        // Ensure selection is valid (exists in list), otherwise default to first
        final validSelection = levels.any((l) => l.id == currentSelection) 
            ? currentSelection 
            : (levels.isNotEmpty ? levels.first.id : '');

        if (validSelection != _selectedLevels[student.studentId]) {
             // Defer state update to avoid build error
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted) {
                 setState(() => _selectedLevels[student.studentId] = validSelection);
               }
             });
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${student.firstName} ${student.lastName}'),
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
                setState(() => _selectedLevels[student.studentId] = val);
              }
            },
          ),
        );
      },
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent et élèves restaurés avec succès ✅')),
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
