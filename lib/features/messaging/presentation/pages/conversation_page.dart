import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/conversation_model.dart';
import '../providers/messaging_providers.dart';
import '../widgets/message_bubble.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({
    super.key,
    required this.conversationId,
    this.initialConversation,
  });

  final String conversationId;
  final ConversationModel? initialConversation;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  static const int _maxMessageChars = 1000;

  late final TextEditingController _messageController;
  late final ScrollController _scrollController;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUid = ref.read(currentUserProvider)?.uid;
      if (currentUid != null && mounted && widget.initialConversation != null) {
        ref.read(messagingControllerProvider.notifier).markRead(
          conversationId: widget.conversationId,
          uid: currentUid,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (text.length > _maxMessageChars) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message must be 1000 characters or less.'),
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final myProfile = ref.read(myProfileProvider).asData?.value;
    if (myProfile == null) return;

    final conversation = widget.initialConversation;
    if (conversation == null) {
      // Parse conversation ID to get otherUid
      final parts = widget.conversationId.split('_');
      if (parts.length != 2) return;

      final otherUid = parts[0] == currentUser.uid ? parts[1] : parts[0];
      // We need to fetch the other user's profile info
      // For now, we'll pass empty/default values and let the datasource handle it

      setState(() => _isSending = true);

      try {
        await ref.read(messagingControllerProvider.notifier).sendMessage(
          conversationId: widget.conversationId,
          text: text,
          otherUid: otherUid,
          otherName: 'User',
          otherAvatarUrl: null,
          myName: myProfile.name,
          myAvatarUrl: myProfile.avatarUrl,
        );

        _messageController.clear();
        _scrollToBottom();
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    } else {
      final otherUid = conversation.getOtherUid(currentUser.uid);
      final otherName = conversation.getOtherName(currentUser.uid);
      final otherAvatarUrl = conversation.getOtherAvatarUrl(currentUser.uid);

      setState(() => _isSending = true);

      try {
        await ref.read(messagingControllerProvider.notifier).sendMessage(
          conversationId: widget.conversationId,
          text: text,
          otherUid: otherUid,
          otherName: otherName,
          otherAvatarUrl: otherAvatarUrl,
          myName: myProfile.name,
          myAvatarUrl: myProfile.avatarUrl,
        );

        _messageController.clear();
        _scrollToBottom();
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider)?.uid ?? '';
    final messagesState = ref.watch(conversationMessagesProvider(
      widget.conversationId,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialConversation != null
              ? widget.initialConversation!.getOtherName(currentUid)
              : 'Message',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Text(
                        'No messages yet. Start the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.appColors.mutedText),
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message.senderUid == currentUid;

                    return MessageBubble(
                      message: message,
                      isSender: isSender,
                    );
                  },
                );
              },
              loading: () => const Center(child: AppLoader()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Text(
                    'Unable to load messages.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    maxLength: _maxMessageChars,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.md,
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
