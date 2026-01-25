import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/student_absence_model.dart';
import '../../../models/student_model.dart';
import '../../../services/student_absence_service.dart';
import '../../../services/student_service.dart';
import '../../../core/helpers/date_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class ManagerAbsenceListScreen extends ConsumerStatefulWidget {
  const ManagerAbsenceListScreen({super.key});

  @override
  ConsumerState<ManagerAbsenceListScreen> createState() => _ManagerAbsenceListScreenState();
}

class _ManagerAbsenceListScreenState extends ConsumerState<ManagerAbsenceListScreen> {
  late Stream<List<StudentAbsenceModel>> _absencesStream;
  final StudentAbsenceService _absenceService = StudentAbsenceService();
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _absencesStream = _absenceService.getAllRecentAbsences(rawdhaId, limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('absence.manager_title'.tr()),
      ),
      body: StreamBuilder<List<StudentAbsenceModel>>(
        stream: _absencesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final absences = snapshot.data ?? [];
          if (absences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('absence.no_any'.tr(), style: const TextStyle(color: AppTheme.textGray)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: absences.length,
            itemBuilder: (context, index) {
              final absence = absences[index];
              return _AbsenceListItem(absence: absence, studentService: _studentService);
            },
          );
        },
      ),
    );
  }
}

class _AbsenceListItem extends ConsumerWidget {
  final StudentAbsenceModel absence;
  final StudentService studentService;

  const _AbsenceListItem({required this.absence, required this.studentService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    return FutureBuilder<StudentModel?>(
      future: studentService.getStudentById(rawdhaId, absence.studentId),
      builder: (context, snapshot) {
        final student = snapshot.data;
        final studentName = student != null ? '${student.firstName} ${student.lastName}' : 'Élève inconnu';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            title: Text(
              studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Motif: ${'absence.causes.${absence.cause}'.tr()}',
                  style: const TextStyle(color: AppTheme.textDark),
                ),
                if (absence.description != null && absence.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      absence.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                  ),
              ],
            ),
            trailing: Text(
              DateHelper.formatDateShort(context, absence.startDate),
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ),
        );
      },
    );
  }
}
