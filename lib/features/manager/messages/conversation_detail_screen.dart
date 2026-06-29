import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/widgets/manager_footer.dart';
import '../../../models/parent_message_model.dart';
import '../../../services/parent_message_service.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String parentName;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.parentName,
  });

  @override
  ConsumerState<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends ConsumerState<ConversationDetailScreen> {
  final _service = ParentMessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Stream<List<ParentMessageModel>> _messagesStream;
  bool _isSending = false;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = _service.getMessages(widget.conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.markConversationAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final rawdhaId = ref.read(currentRawdhaIdProvider);
    if (rawdhaId == null) return;

    final canSend = await _service.canSendMessage(widget.conversationId);
    if (!canSend) {
      if (mounted) {
        setState(() => _limitReached = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messages.daily_limit_reached_admin'.tr()),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      await _service.sendMessage(
        rawdhaId: rawdhaId,
        parentId: widget.conversationId.split('_').last,
        parentName: widget.parentName,
        message: text,
        senderType: 'admin',
      );
      _messageController.clear();
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error'.tr()}: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.parentName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ParentMessageModel>>(
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
                          'messages.load_error'.tr(),
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
                        Icon(Icons.chat_outlined, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text(
                          'messages.admin_empty_title'.tr(),
                          style: TextStyle(color: AppTheme.textGray, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'messages.retention_note'.tr(),
                          style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAdmin = msg.senderType == 'admin';
                    final showDate = index == 0 ||
                        messages[index].createdAt.day != messages[index - 1].createdAt.day;
                    return Column(
                      children: [
                        if (showDate)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.textGray.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateHelper.formatDateLong(context, msg.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                            ),
                          ),
                        _MessageBubble(
                          message: msg.message,
                          time: DateHelper.formatDateShort(context, msg.createdAt),
                          isAdmin: isAdmin,
                          parentName: widget.parentName,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_limitReached)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.warningOrange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'messages.daily_limit_banner'.tr(),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'messages.write_hint_admin'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          const ManagerFooter(),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isAdmin;
  final String parentName;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isAdmin,
    required this.parentName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAdmin ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
            bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  parentName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isAdmin ? Colors.white : AppTheme.textDark,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isAdmin ? Colors.white.withOpacity(0.7) : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
