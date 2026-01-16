import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/module_model.dart';
import '../../../models/school_level_model.dart';
import '../../../services/module_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class ModuleFormScreen extends ConsumerStatefulWidget {
  final ModuleModel? module;
  final String levelId;

  const ModuleFormScreen({super.key, this.module, required this.levelId});

  @override
  ConsumerState<ModuleFormScreen> createState() => _ModuleFormScreenState();
}

class _ModuleFormScreenState extends ConsumerState<ModuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Champs principaux
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Champs contenu
  final _letterController = TextEditingController();
  final _wordController = TextEditingController();
  final _numberController = TextEditingController();
  final _colorController = TextEditingController();
  final _prayerController = TextEditingController();
  final _songController = TextEditingController();

  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  final ModuleService _moduleService = ModuleService();

  @override
  void initState() {
    super.initState();
    if (widget.module != null) {
      _titleController.text = widget.module!.title;
      _descriptionController.text = widget.module!.description;
      _letterController.text = widget.module!.letter;
      _wordController.text = widget.module!.word;
      _numberController.text = widget.module!.number;
      _colorController.text = widget.module!.color;
      _prayerController.text = widget.module!.prayer ?? '';
      _songController.text = widget.module!.song ?? '';
      
      _selectedDateRange = DateTimeRange(
        start: widget.module!.startDate,
        end: widget.module!.endDate,
      );
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une période')),
      );
      return;
    }

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: ID Rawdha non trouvé')));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final module = ModuleModel(
        rawdhaId: rawdhaId,
        id: widget.module?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        levelId: widget.levelId,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        letter: _letterController.text.trim(),
        word: _wordController.text.trim(),
        number: _numberController.text.trim(),
        color: _colorController.text.trim(),
        prayer: _prayerController.text.trim(),
        song: _songController.text.trim(),
      );

      if (widget.module != null) {
        await _moduleService.updateModule(module);
      } else {
        await _moduleService.addModule(module);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.module != null ? 'Module modifié' : 'Module ajouté'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module != null ? 'module.edit_title'.tr() : 'module.add_title'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre & Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'module.form_title_label'.tr(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (v) => v!.isEmpty ? 'common.required'.tr() : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'module.form_desc_label'.tr(),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('module.period_label').tr(),
                      subtitle: Text(_selectedDateRange == null
                          ? 'module.select_dates'.tr()
                          : 'module.period_format'.tr(args: [
                              DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start),
                              DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end),
                              ( _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1).toString()
                            ])),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _isLoading ? null : _pickDateRange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Contenu Éducatif
            // Contenu Éducatif
            Text('module.form_content_title'.tr(), style: AppTheme.lightTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildField(_letterController, 'module.letter_hint'.tr(), Icons.abc)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildField(_numberController, 'module.number_hint'.tr(), Icons.numbers)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildField(_wordController, 'module.word_hint'.tr(), Icons.text_fields)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildField(_colorController, 'module.color_hint'.tr(), Icons.color_lens)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(_prayerController, 'module.prayer_hint'.tr(), Icons.mosque),
                    const SizedBox(height: 12),
                    _buildField(_songController, 'module.song_hint'.tr(), Icons.music_note),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _saveModule,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('module.save_btn'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 48), // Increased bottom padding for system nav
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
