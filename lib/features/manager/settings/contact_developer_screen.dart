import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/developer_service.dart';
import '../../../models/developer_model.dart';

class ContactDeveloperScreen extends StatefulWidget {
  const ContactDeveloperScreen({super.key});

  @override
  State<ContactDeveloperScreen> createState() => _ContactDeveloperScreenState();
}

class _ContactDeveloperScreenState extends State<ContactDeveloperScreen> {
  final DeveloperService _developerService = DeveloperService();
  late Stream<DeveloperModel?> _developerInfoStream;

  @override
  void initState() {
    super.initState();
    _developerService.seedDeveloperData();
    _developerInfoStream = _developerService.getDeveloperInfo();
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Remove non-numeric characters for WhatsApp link
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/$cleanNumber';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'school.developer.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DeveloperModel?>(
        stream: _developerInfoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final developer = snapshot.data;
          if (developer == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: AppTheme.textGray),
                  const SizedBox(height: 16),
                  Text(
                    'common.error'.tr(),
                    style: const TextStyle(color: AppTheme.textGray),
                  ),
                ],
              ),
            );
          }

          final isArabic = context.locale.languageCode == 'ar';
          final bio = isArabic ? developer.bioAr : developer.bioFr;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with Gradient
                _buildHeader(context, developer),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio Section
                      if (bio != null) ...[
                        Text(
                          'school.developer.desc'.tr(), // Use translation key
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            bio,
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Contact Section
                      Text(
                        'school.contact'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact Group
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (developer.phone != null) ...[
                              _buildContactListTile(
                                icon: Icons.phone_rounded,
                                title: 'school.developer.call'.tr(),
                                subtitle: developer.phone!,
                                color: Colors.blue,
                                onTap: () => _makePhoneCall(developer.phone!),
                              ),
                              const Divider(height: 1, indent: 64),
                              /*_buildContactListTile(
                                icon: Icons.message_rounded,
                                title: 'school.developer.whatsapp'.tr(),
                                subtitle: 'Direct Chat',
                                color: Colors.green,
                                onTap: () => _launchWhatsApp(developer.phone!),
                              ),*/
                              const Divider(height: 1, indent: 64),
                              if (developer.isUpdateAvailable && developer.updateUrl != null) ...[
                                _buildContactListTile(
                                  icon: Icons.system_update,
                                  title: 'updates.update_btn'.tr(),
                                  subtitle: 'updates.title'.tr(),
                                  color: Colors.green,
                                  onTap: () => _launchUrl(developer.updateUrl!),
                                ),
                                const Divider(height: 1, indent: 64),
                              ],
                            ],
                            if (developer.email != null) ...[
                              _buildContactListTile(
                                icon: Icons.email_rounded,
                                title: 'school.developer.email'.tr(),
                                subtitle: developer.email!,
                                color: Colors.redAccent,
                                onTap: () => _sendEmail(developer.email!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Social Links if available
                      if (developer.socialLinks != null && developer.socialLinks!.isNotEmpty) ...[
                         Text(
                          'Social Media', // Could be localized
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSocialRow(developer.socialLinks!),
                      ],
                      
                      const SizedBox(height: 40),
                      
                      // Branding footer (Optional)
                      Center(
                        child: Opacity(
                          opacity: 0.5,
                          child: Text(
                            '© 2026 Rawdhati Software Solutions',
                            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DeveloperModel developer) {
    final isArabic = context.locale.languageCode == 'ar';
    final name = isArabic ? developer.nameAr : developer.nameFr;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withBlue(200),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: AppTheme.backgroundLight,
              backgroundImage: developer.photoUrl != null ? NetworkImage(developer.photoUrl!) : null,
              child: developer.photoUrl == null 
                ? Icon(Icons.person, size: 56, color: AppTheme.primaryBlue) 
                : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'school.developer.job'.tr(),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textGray, fontSize: 13),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildSocialRow(Map<String, dynamic> links) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (links['facebook'] != null)
           _SocialButton(
             icon: Icons.facebook,
             color: const Color(0xFF1877F2),
             onTap: () => _launchUrl(links['facebook']),
           ),
        if (links['linkedin'] != null) ...[
          const SizedBox(width: 16),
           _SocialButton(
             icon: Icons.link, // Custom LinkedIn icon would be better if available
             color: const Color(0xFF0A66C2),
             onTap: () => _launchUrl(links['linkedin']),
           ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
