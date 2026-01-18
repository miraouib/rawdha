import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/manager_footer.dart';
import '../../../models/school_level_model.dart';
import '../../../services/school_service.dart';
import 'level_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

/// Écran principal de gestion de l'école (Niveaux)
class SchoolManagementScreen extends ConsumerStatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  ConsumerState<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends ConsumerState<SchoolManagementScreen> {
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rawdhaId = ref.read(currentRawdhaIdProvider);
      if (rawdhaId != null) {
        _schoolService.initializeDefaultLevels(rawdhaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('school.levels_management'.tr()),
      ),
      body: StreamBuilder<List<SchoolLevelModel>>(
        stream: _schoolService.getLevels(ref.watch(currentRawdhaIdProvider) ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chargement des niveaux...'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _LevelCard(level: snapshot.data![index]);
            },
          );
        },
      ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final SchoolLevelModel level;

  const _LevelCard({required this.level});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData icon;

    if (level.id.endsWith(SchoolLevelModel.level3Id)) {
      cardColor = AppTheme.primaryBlue;
      icon = Icons.child_care;
    } else if (level.id.endsWith(SchoolLevelModel.level4Id)) {
      cardColor = AppTheme.accentTeal;
      icon = Icons.face;
    } else if (level.id.endsWith(SchoolLevelModel.level5Id)) {
      cardColor = AppTheme.accentOrange;
      icon = Icons.school;
    } else {
      cardColor = AppTheme.textGray;
      icon = Icons.class_;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelDetailScreen(level: level),
          ),
        );
      },

      child: Container(
        // height removed for dynamic sizing
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.locale.languageCode == 'ar' ? level.nameAr : level.nameFr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.locale.languageCode == 'ar' ? level.descriptionAr : level.descriptionFr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
