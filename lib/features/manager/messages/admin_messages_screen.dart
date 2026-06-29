import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../models/parent_message_model.dart';
import '../../../services/parent_message_service.dart';
import '../../../core/helpers/date_helper.dart';

class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  final _service = ParentMessageService();
  late Stream<List<ParentMessageModel>> _messagesStream;

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _messagesStream = _service.getMessages(rawdhaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Messages des parents'),
      ),
      body: StreamBuilder<List<ParentMessageModel>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                  const SizedBox(height: 12),
                  Text(
                    'Impossible de charger les messages',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun message pour le moment',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return _MessageCard(
                message: msg,
                onTap: () => _service.markAsRead(msg.id),
                onDelete: () => _confirmDelete(msg.id),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              _service.deleteMessage(messageId);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ParentMessageModel message;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.message,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onTap: () {
          if (!message.isRead) onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: message.isRead ? AppTheme.borderColor : AppTheme.primaryBlue.withOpacity(0.3),
              width: message.isRead ? 1 : 2,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.parentName,
                          style: TextStyle(
                            fontWeight: message.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateHelper.formatDateFull(context, message.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  ),
                  if (!message.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.message,
                style: const TextStyle(color: AppTheme.textDark, height: 1.4, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
