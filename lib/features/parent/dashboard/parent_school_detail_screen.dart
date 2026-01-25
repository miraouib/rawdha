import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_config_model.dart';
import '../../../services/school_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

import '../../../core/widgets/parent_footer.dart';

class ParentSchoolDetailScreen extends ConsumerStatefulWidget {
  const ParentSchoolDetailScreen({super.key});

  @override
  ConsumerState<ParentSchoolDetailScreen> createState() => _ParentSchoolDetailScreenState();
}

class _ParentSchoolDetailScreenState extends ConsumerState<ParentSchoolDetailScreen> {
  late Stream<SchoolConfigModel> _schoolConfigStream;
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _schoolConfigStream = _schoolService.getSchoolConfig(rawdhaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      bottomNavigationBar: const ParentFooter(),
      appBar: AppBar(
        title: Text('parent.view_school_details'.tr()),
      ),
      body: StreamBuilder<SchoolConfigModel>(
        stream: _schoolConfigStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune information disponible'));
          }

          final config = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Section
                if (config.logoUrl != null && config.logoUrl!.isNotEmpty)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        config.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/logo.png'),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // School Name
                Text(
                  config.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                


                const SizedBox(height: 40),

                // Details Cards
                _buildInfoCard(
                  context,
                  title: 'school.fields.address'.tr(),
                  content: config.address ?? 'common.not_defined'.tr(),
                  icon: Icons.location_on,
                  color: AppTheme.primaryPurple,
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  context,
                  title: 'school.fields.phone'.tr(),
                  content: config.phone ?? 'common.not_defined'.tr(),
                  icon: Icons.phone,
                  color: AppTheme.primaryBlue,
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  context,
                  title: 'school.fields.email'.tr(),
                  content: config.email ?? 'common.not_defined'.tr(),
                  icon: Icons.email,
                  color: AppTheme.accentPink,
                ),

                const SizedBox(height: 40),
                
                // Footer
                Text(
                  'app_name'.tr(),
                  style: TextStyle(
                    color: AppTheme.textLight.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
