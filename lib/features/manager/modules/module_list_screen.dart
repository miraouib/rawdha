import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_level_model.dart';
import '../../../models/module_model.dart';
import '../../../services/module_service.dart';
import '../../../services/school_service.dart';
import 'module_form_screen.dart';

/// Écran de gestion des modules (avec Tabs par niveau)
class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({super.key});

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SchoolService _schoolService = SchoolService();
  final ModuleService _moduleService = ModuleService();
  
  // Niveaux (IDs fixes pour simplifier)
  final List<String> _levelIds = [
    SchoolLevelModel.level3Id,
    SchoolLevelModel.level4Id,
    SchoolLevelModel.level5Id,
  ];

  @override
  void initState() {
    super.initState();
    _schoolService.initializeDefaultLevels();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('module.management_title').tr(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGray,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'levels.level_3'),
            Tab(text: 'levels.level_4'),
            Tab(text: 'levels.level_5'),
          ].map((t) => Tab(text: t.text!.tr())).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _levelIds.map((levelId) => _buildModuleView(levelId)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final levelId = _levelIds[_tabController.index];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleFormScreen(levelId: levelId),
            ),
          );
        },
        label: Text('module.new_module').tr(),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.accentTeal,
      ),
    );
  }

  /// Vue par niveau : Affiche uniquement le module actif, avec option de voir l'historique
  Widget _buildModuleView(String levelId) {
    return StreamBuilder<List<ModuleModel>>(
      stream: _moduleService.getModulesForLevel(levelId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final modules = snapshot.data ?? [];

        // Trouver le module actif (le tableau est déjà trié ou pas, mais on cherche isCurrentlyActive)
        final activeModule = modules.where((m) => m.isCurrentlyActive).firstOrNull;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Module Actif
              Text(
                'module.active_label'.tr(),
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                   color: AppTheme.textGray,
                   fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              if (activeModule != null)
                _buildActiveModuleCard(activeModule, levelId)
              else
                 _buildEmptyActiveState(),

              const SizedBox(height: 32),
              
              // Bouton pour gérer l'historique
              ElevatedButton.icon(
                onPressed: () {
                  _showModuleHistorySheet(context, modules, levelId);
                },
                icon: const Icon(Icons.history),
                label: Text('module.manage_all').tr(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveModuleCard(ModuleModel module, String levelId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.successGreen, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 24),
                const SizedBox(width: 8),
                  Text(
                    'module.active_badge'.tr(),  
                    style: const TextStyle(
                      color: AppTheme.successGreen, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              module.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            if (module.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  module.description,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textGray),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            if (module.startDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.date_range, size: 16, color: AppTheme.textGray),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('dd/MM').format(module.startDate)} - ${DateFormat('dd/MM').format(module.endDate)}',
                      style: const TextStyle(color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _buildContentGrid(module),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: Text('module.edit_btn').tr(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModuleFormScreen(module: module, levelId: levelId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentGrid(ModuleModel module) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        if (module.letter.isNotEmpty) _contentItem(Icons.abc, module.letter, Colors.orange),
        if (module.number.isNotEmpty) _contentItem(Icons.numbers, module.number, Colors.blue),
        if (module.word.isNotEmpty) _contentItem(Icons.text_fields, module.word, Colors.green),
        if (module.color.isNotEmpty) _contentItem(Icons.color_lens, module.color, Colors.purple),
      ],
    );
  }

  Widget _contentItem(IconData icon, String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyActiveState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
           Icon(Icons.disabled_by_default_outlined, size: 64, color: AppTheme.textLight),
           const SizedBox(height: 16),
             Text(
             'module.no_active_module'.tr(),
             style: const TextStyle(fontSize: 18, color: AppTheme.textGray),
           ),
           const SizedBox(height: 8),
             Text(
             'module.no_active_desc'.tr(),
             textAlign: TextAlign.center,
             style: const TextStyle(color: AppTheme.textLight),
           ),
        ],
      ),
    );
  }

  void _showModuleHistorySheet(BuildContext context, List<ModuleModel> modules, String levelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('module.all_modules'.tr(), style: AppTheme.lightTheme.textTheme.titleLarge),
                ),
                Expanded(
                  child: modules.isEmpty 
                    ? const Center(child: Text('Aucun module.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final module = modules[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: module.isCurrentlyActive ? AppTheme.successGreen : Colors.grey[200],
                              child: Icon(
                                module.isCurrentlyActive ? Icons.check : Icons.book, 
                                color: module.isCurrentlyActive ? Colors.white : Colors.grey,
                              ),
                            ),
                            title: Text(
                              module.title,
                              style: TextStyle(fontWeight: module.isCurrentlyActive ? FontWeight.bold : FontWeight.normal),
                            ),
                            subtitle: Text(
                              'module.period_format'.tr(args: [
                                DateFormat('dd/MM').format(module.startDate),
                                DateFormat('dd/MM').format(module.endDate),
                                _calculateWorkingDays(module.startDate, module.endDate).toString()
                              ]),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pop(context); // Fermer la sheet
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => ModuleFormScreen(module: module, levelId: levelId)),
                                );
                              },
                            ),
                            onTap: () async {
                              // Activer rapidement au clic ? Ou ouvrir le détail ?
                              // Pour l'instant on ouvre le form
                              Navigator.pop(context);
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => ModuleFormScreen(module: module, levelId: levelId)),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  int _calculateWorkingDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}
