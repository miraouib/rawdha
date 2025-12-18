import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/module_model.dart';

class ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final bool isFullPage;

  const ModuleCard({
    super.key,
    required this.module,
    this.isFullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.gradientCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.auto_awesome, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),
          if (module.description.isNotEmpty)
            Text(
              module.description,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          const Divider(color: Colors.white24, height: 32),
          _buildContentGrid(context),
        ],
      ),
    );
  }

  Widget _buildContentGrid(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (module.letter.isNotEmpty) _ContentChip(icon: Icons.abc, text: module.letter, label: 'module.letter'.tr()),
        if (module.number.isNotEmpty) _ContentChip(icon: Icons.numbers, text: module.number, label: 'module.number'.tr()),
        if (module.word.isNotEmpty) _ContentChip(icon: Icons.text_fields, text: module.word, label: 'module.word'.tr()),
        if (module.color.isNotEmpty) _ContentChip(icon: Icons.color_lens, text: module.color, label: 'module.color'.tr()),
        if (module.prayer != null && module.prayer!.isNotEmpty) 
           _ContentChip(icon: Icons.mosque, text: module.prayer!, label: 'module.prayer'.tr(), fullWidth: true),
        if (module.song != null && module.song!.isNotEmpty) 
           _ContentChip(icon: Icons.music_note, text: module.song!, label: 'module.song'.tr(), fullWidth: true),
      ],
    );
  }
}

class _ContentChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final String label;
  final bool fullWidth;

  const _ContentChip({required this.icon, required this.text, required this.label, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : (MediaQuery.of(context).size.width - (fullWidth ? 40 : 80)) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
