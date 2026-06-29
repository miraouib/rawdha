import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/widgets/parent_footer.dart';
import '../../../models/parent_model.dart';
import '../../../models/parent_message_model.dart';
import '../../../services/parent_message_service.dart';

class ParentConversationScreen extends ConsumerStatefulWidget {
  final ParentModel parent;
  const ParentConversationScreen({super.key, required this.parent});

  @override
  ConsumerState<ParentConversationScreen> createState() => _ParentConversationScreenState();
}

class _ParentConversationScreenState extends ConsumerState<ParentConversationScreen> {
  final _service = ParentMessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late String _conversationId;
  late Stream<List<ParentMessageModel>> _messagesStream;
  bool _isSending = false;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _conversationId = '${widget.parent.rawdhaId}_${widget.parent.id}';
    _messagesStream = _service.getMessages(_conversationId);
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

    final canSend = await _service.canSendMessage(_conversationId);
    if (!canSend) {
      if (mounted) {
        setState(() => _limitReached = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messages.daily_limit_reached'.tr()),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      await _service.sendMessage(
        rawdhaId: widget.parent.rawdhaId,
        parentId: widget.parent.id,
        parentName: '${widget.parent.firstName} ${widget.parent.lastName}',
        message: text,
        senderType: 'parent',
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
        title: Text('messages.admin_title'.tr()),
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
                          'messages.parent_empty_title'.tr(),
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
                    final isParent = msg.senderType == 'parent';
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
                        _ParentMessageBubble(
                          message: msg.message,
                          time: DateHelper.formatDateShort(context, msg.createdAt),
                          isParent: isParent,
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
                      hintText: 'messages.write_hint'.tr(),
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
          const ParentFooter(),
        ],
      ),
    );
  }
}

class _ParentMessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isParent;

  const _ParentMessageBubble({
    required this.message,
    required this.time,
    required this.isParent,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isParent ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isParent ? const Radius.circular(16) : Radius.zero,
            bottomRight: isParent ? Radius.zero : const Radius.circular(16),
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
            if (!isParent)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'messages.admin_label'.tr(),
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
                color: isParent ? Colors.white : AppTheme.textDark,
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
                  color: isParent ? Colors.white.withOpacity(0.7) : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
