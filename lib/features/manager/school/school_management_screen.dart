import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_level_model.dart';
import '../../../services/school_service.dart';
import 'level_detail_screen.dart';

/// Écran principal de gestion de l'école (Niveaux)
class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen> {
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    // S'assurer que les niveaux existent
    _schoolService.initializeDefaultLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('school.levels_management'.tr()),
      ),
      body: StreamBuilder<List<SchoolLevelModel>>(
        stream: _schoolService.getLevels(),
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

    switch (level.id) {
      case SchoolLevelModel.level3Id:
        cardColor = AppTheme.primaryBlue;
        icon = Icons.child_care;
        break;
      case SchoolLevelModel.level4Id:
        cardColor = AppTheme.accentTeal;
        icon = Icons.face;
        break;
      case SchoolLevelModel.level5Id:
        cardColor = AppTheme.accentOrange;
        icon = Icons.school;
        break;
      default:
        cardColor = AppTheme.textGray;
        icon = Icons.class_;
    }

    return GestureDetector(
      onTap: () async {
        // Logique "si 1 seule classe, lier directement"
        final schoolService = SchoolService();
        final classCount = await schoolService.countClassesInLevel(level.id);
        
        if (context.mounted) {
          // Pour l'instant on ouvre toujours le détail du niveau
          // Si on veut rediriger direct vers la classe unique, il faudrait
          // récupérer l'ID de la classe unique et aller vers StudentListScreen
          // Mais StudentListScreen n'existe pas encore.
          // Donc on garde la navigation standard pour le moment.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LevelDetailScreen(level: level),
            ),
          );
        }
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
                    'levels.${level.id}'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'levels.${level.id}_desc'.tr(),
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
