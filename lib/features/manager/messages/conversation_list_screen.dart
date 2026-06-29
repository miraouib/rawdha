import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/widgets/manager_footer.dart';
import '../../../services/parent_message_service.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen> {
  final _service = ParentMessageService();
  late Stream<List<ConversationSummary>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    debugPrint('[ConversationList] initState rawdhaId: "$rawdhaId"');
    _conversationsStream = _service.getConversations(rawdhaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('messages.conversations_title'.tr()),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ConversationSummary>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          debugPrint('[ConversationList] state=${snapshot.connectionState} hasData=${snapshot.hasData} hasError=${snapshot.hasError} dataLen=${snapshot.data?.length}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('[ConversationList] ERROR: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                  const SizedBox(height: 12),
                  Text(
                    'messages.load_error'.tr(),
                    style: TextStyle(color: AppTheme.textGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'messages.no_conversations'.tr(),
                    style: TextStyle(color: AppTheme.textGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _ConversationCard(
                conversation: conv,
                onTap: () {
                  context.pushNamed('conversation_detail', extra: conv);
                },
              );
            },
          );
        },
      ),
    ),
          const ManagerFooter(),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationSummary conversation;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: conversation.unreadCount > 0
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : AppTheme.borderColor,
              width: conversation.unreadCount > 0 ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: conversation.unreadCount > 0
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : AppTheme.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: conversation.unreadCount > 0
                      ? AppTheme.primaryBlue
                      : AppTheme.textGray,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.parentName,
                            style: TextStyle(
                              fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          DateHelper.formatDateShort(context, conversation.lastMessageAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
