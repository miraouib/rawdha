import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/level_helper.dart';
import '../../../models/student_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/parent_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class StudentDetailScreen extends ConsumerWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('${student.firstName} ${student.lastName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               context.pushNamed('student_edit', extra: student);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                    child: student.photoUrl == null ? Text(student.firstName[0], style: const TextStyle(fontSize: 40)) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${student.firstName} ${student.lastName}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    LevelHelper.getLevelName(student.levelId, context),
                    style: TextStyle(fontSize: 16, color: AppTheme.textGray),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details Section
            _buildSectionTitle('student.personal_info'.tr()),
            _buildInfoTile(Icons.wc, 'student.gender'.tr(), student.gender == 'boy' ? 'student.boy'.tr() : 'student.girl'.tr()),
           if (student.birthdate != null)
              _buildInfoTile(Icons.cake, 'student.birthdate'.tr(), DateFormat('dd/MM/yyyy').format(student.birthdate!)),
            
            const SizedBox(height: 24),
            _buildSectionTitle('student.responsible'.tr()),
            if (student.parentIds.isNotEmpty)
              FutureBuilder<ParentModel?>(
                future: ParentService().getParentById(rawdhaId, student.parentIds.first),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return _buildInfoTile(Icons.error_outline, 'parent.parent_info'.tr(), 'student.not_found'.tr());
                  }
                  final parent = snapshot.data!;
                  return Column(
                    children: [
                      _buildClickableParentTile(context, parent),
                      _buildCopyablePhoneTile(context, parent.phone),
                    ],
                  );
                },
              )
            else
              _buildInfoTile(Icons.warning, 'parent.parent_info'.tr(), 'student.no_parent_linked'.tr()),

            // TODO: Add payment info etc.
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textGray, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyablePhoneTile(BuildContext context, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.phone, color: AppTheme.textGray, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('student.phone'.tr(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            color: AppTheme.primaryBlue,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('student.phone_copied'.tr(args: [phone])),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryBlue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClickableParentTile(BuildContext context, ParentModel parent) {
    return InkWell(
      onTap: () {
        context.pushNamed('parent_payment_history', extra: parent);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.person, color: AppTheme.textGray, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('student.parent_name'.tr(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(
                    '${parent.firstName} ${parent.lastName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}
