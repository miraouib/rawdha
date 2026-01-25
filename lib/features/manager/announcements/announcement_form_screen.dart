import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement_model.dart';
import '../../../services/announcement_service.dart';
import '../../../models/school_level_model.dart';
import '../../../services/school_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/date_helper.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  AnnouncementTag _selectedTag = AnnouncementTag.info;
  DateTimeRange? _selectedDateRange;
  String? _selectedLevelId; // null = All levels

  
  bool _isLoading = false;
  late Stream<List<SchoolLevelModel>> _levelsStream;
  final SchoolService _schoolService = SchoolService();
  
  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _levelsStream = _schoolService.getLevels(rawdhaId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      locale: const Locale('fr'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate Duration
      if (picked.duration.inDays > 14) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text('announcements.errors.max_duration'.tr()),
             backgroundColor: Colors.red,
           ));
        }
        return;
      }
      
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.error'.tr())));
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

    try {
      final announcement = AnnouncementModel(
        rawdhaId: rawdhaId,
        id: '',
        title: _titleController.text.trim(),
        tag: _selectedTag,
        content: _contentController.text.trim(),
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59)), // End of day
        createdAt: DateTime.now(),
        createdBy: 'manager', // TODO: Use real user ID
        targetLevelId: _selectedLevelId,
      );

      await AnnouncementService().createAnnouncement(rawdhaId, announcement);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Succès')));
      }
    } catch (e) {
      // Handle overlap error explicitly if possible, or generic
      String errorMsg = e.toString();
      if (errorMsg.contains('overlap')) {
        errorMsg = 'announcements.errors.overlap'.tr();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg.replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text('announcements.form_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'announcements.field_title'.tr(),
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v?.isNotEmpty == true ? null : 'common.error'.tr(),
              ),
              const SizedBox(height: 16),

              // Level Target Selector
              StreamBuilder<List<SchoolLevelModel>>(
                stream: _levelsStream,
                builder: (context, snapshot) {
                  final levels = snapshot.data ?? [];
                  return DropdownButtonFormField<String?>(
                    value: _selectedLevelId,
                    decoration: InputDecoration(
                      labelText: 'announcements.target_level'.tr(),
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('announcements.all_levels'.tr()),
                      ),
                      ...levels.map((level) {
                        return DropdownMenuItem<String?>(
                          value: level.id,
                          child: Text(Localizations.localeOf(context).languageCode == 'ar' ? level.nameAr : level.nameFr),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _selectedLevelId = v),
                  );
                },
              ),
              const SizedBox(height: 16),

              
              // Tag Selector
              DropdownButtonFormField<AnnouncementTag>(
                value: _selectedTag,
                decoration: InputDecoration(
                   labelText: 'announcements.field_tag'.tr(),
                   prefixIcon: const Icon(Icons.label),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AnnouncementTag.values.map((tag) {
                  return DropdownMenuItem(
                    value: tag,
                    child: Text(
                      AnnouncementModel(
                        rawdhaId: '',
                        id: '', title: '', tag: tag, content: '', 
                        startDate: DateTime.now(), endDate: DateTime.now(), 
                        createdAt: DateTime.now(), createdBy: '',
                        targetLevelId: null,
                      ).tagLabel
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedTag = v!),
              ),
              const SizedBox(height: 16),
              
              // Date Picker
              InkWell(
                onTap: () => _pickDateRange(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDateRange == null
                            ? 'announcements.field_dates'.tr()
                            : '${DateHelper.formatDateShort(context, _selectedDateRange!.start)} - ${DateHelper.formatDateShort(context, _selectedDateRange!.end)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedDateRange == null ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Content
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'announcements.field_content'.tr(),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v?.isNotEmpty == true ? null : 'common.error'.tr(),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAnnouncement,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('common.save'.tr(), style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
