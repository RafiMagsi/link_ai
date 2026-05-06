import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_ai/features/explore/presentation/widgets/shadow_style.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_user_avatar.dart';
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

class _ConversationPageState extends ConsumerState<ConversationPage>
    with WidgetsBindingObserver {
  static const int _maxMessageChars = 1000;

  late final TextEditingController _messageController;
  late final ScrollController _scrollController;
  late final FocusNode _messageFocusNode;

  Timer? _keyboardScrollTimer;
  double _lastBottomInset = 0;
  int _lastMessageCount = 0;

  bool _isSending = false;
  bool _isPullUpRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageFocusNode = FocusNode()..addListener(_handleMessageFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUid = ref.read(currentUserProvider)?.uid;
      if (currentUid != null && mounted && widget.initialConversation != null) {
        ref
            .read(messagingControllerProvider.notifier)
            .markRead(conversationId: widget.conversationId, uid: currentUid);
      }
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _keyboardScrollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _messageFocusNode.removeListener(_handleMessageFocusChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final bottomInset = View.of(context).viewInsets.bottom;
    final keyboardOpened = bottomInset > _lastBottomInset;
    _lastBottomInset = bottomInset;

    if (keyboardOpened && _messageFocusNode.hasFocus) {
      _scheduleKeyboardScrollToBottom();
    }
  }

  void _handleMessageFocusChanged() {
    if (_messageFocusNode.hasFocus) {
      _scheduleKeyboardScrollToBottom();
    }
  }

  void _scheduleKeyboardScrollToBottom() {
    _keyboardScrollTimer?.cancel();
    _keyboardScrollTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _scrollToBottom(animated: true);
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final target = position.maxScrollExtent;

    if ((target - position.pixels).abs() < 10) return;

    if (!animated) {
      _scrollController.jumpTo(target);
      return;
    }

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handlePullUpRefresh(String currentUid) async {
    if (_isPullUpRefreshing) return;

    setState(() => _isPullUpRefreshing = true);

    try {
      ref.invalidate(conversationMessagesProvider(widget.conversationId));

      if (currentUid.isNotEmpty && widget.initialConversation != null) {
        await ref
            .read(messagingControllerProvider.notifier)
            .markRead(conversationId: widget.conversationId, uid: currentUid);
      }

      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      if (mounted) {
        setState(() => _isPullUpRefreshing = false);
      }
    }
  }

  String _otherName(String currentUid) {
    final conversation = widget.initialConversation;
    if (conversation == null) return 'Message';

    final name = conversation.getOtherName(currentUid).trim();
    return name.isEmpty ? 'AI Builder' : name;
  }

  String? _otherAvatarUrl(String currentUid) {
    final conversation = widget.initialConversation;
    if (conversation == null) return null;
    return conversation.getOtherAvatarUrl(currentUid);
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
        await ref
            .read(messagingControllerProvider.notifier)
            .sendMessage(
              conversationId: widget.conversationId,
              text: text,
              otherUid: otherUid,
              otherName: 'User',
              otherAvatarUrl: null,
              myName: myProfile.name,
              myAvatarUrl: myProfile.avatarUrl,
            );

        _messageController.clear();
        if (!mounted) return;
        setState(() => _isSending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToBottom(animated: true);
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isSending = false);
        }
        rethrow;
      }
    } else {
      final otherUid = conversation.getOtherUid(currentUser.uid);
      final otherName = conversation.getOtherName(currentUser.uid);
      final otherAvatarUrl = conversation.getOtherAvatarUrl(currentUser.uid);

      setState(() => _isSending = true);

      try {
        await ref
            .read(messagingControllerProvider.notifier)
            .sendMessage(
              conversationId: widget.conversationId,
              text: text,
              otherUid: otherUid,
              otherName: otherName,
              otherAvatarUrl: otherAvatarUrl,
              myName: myProfile.name,
              myAvatarUrl: myProfile.avatarUrl,
            );

        _messageController.clear();
        if (!mounted) return;
        setState(() => _isSending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToBottom(animated: true);
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isSending = false);
        }
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider)?.uid ?? '';
    final otherName = _otherName(currentUid);
    final otherAvatarUrl = _otherAvatarUrl(currentUid);
    final colorScheme = Theme.of(context).colorScheme;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final messagesState = ref.watch(
      conversationMessagesProvider(widget.conversationId),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: _ConversationAppBarTitle(
          name: otherName,
          avatarUrl: otherAvatarUrl,
          subtitle: 'AI Links message',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'View profile',
              onPressed: widget.initialConversation == null
                  ? null
                  : () {
                      final otherUid = widget.initialConversation!.getOtherUid(
                        currentUid,
                      );
                      if (otherUid.isEmpty) return;
                      navigateToProfile(
                        context: context,
                        uid: otherUid,
                        isSelfProfile: otherUid == currentUid,
                      );
                    },
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.7),
          child: Container(
            height: 0.7,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.14),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                final metrics = notification.metrics;
                final isAtBottom = metrics.pixels >= metrics.maxScrollExtent;
                final isPullingUp = notification.overscroll > 0;

                if (isAtBottom && isPullingUp) {
                  _handlePullUpRefresh(currentUid);
                  return true;
                }

                return false;
              },
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isPullUpRefreshing
                        ? Padding(
                            key: const ValueKey('refreshing'),
                            padding: const EdgeInsets.only(top: 4, bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Refreshing messages...',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('idle')),
                  ),
                  Expanded(
                    child: messagesState.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppSizes.xl),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.18,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFBFDBFE),
                                          Color(0xFFD8B4FE),
                                          Color(0xFFFBCFE8),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Color(0xFF312E81),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.lg),
                                  Text(
                                    'Start the conversation',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: AppSizes.sm),
                                  Text(
                                    'Send a useful message to $otherName.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.appColors.mutedText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        if (_lastMessageCount != messages.length) {
                          _lastMessageCount = messages.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _scrollToBottom(animated: true);
                          });
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            10,
                            8,
                            10,
                            bottomInset > 0 ? 16 : 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isSender = message.senderUid == currentUid;
                            final previousMessage = index > 0
                                ? messages[index - 1]
                                : null;
                            final nextMessage = index < messages.length - 1
                                ? messages[index + 1]
                                : null;
                            final isSameAsPrevious =
                                previousMessage?.senderUid == message.senderUid;
                            final isSameAsNext =
                                nextMessage?.senderUid == message.senderUid;
                            final showAvatar = !isSender && !isSameAsNext;
                            final topSpacing = isSameAsPrevious ? 2.0 : 6.0;
                            final avatarUrl = otherAvatarUrl;

                            return Padding(
                              padding: EdgeInsets.only(top: topSpacing),
                              child: Row(
                                mainAxisAlignment: isSender
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isSender) ...[
                                    SizedBox(
                                      width: 26,
                                      child: showAvatar
                                          ? AppUserAvatar(
                                              avatarUrl: avatarUrl,
                                              radius: 12,
                                            )
                                          : const SizedBox(width: 24),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: MessageBubble(
                                      message: message,
                                      isSender: isSender,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.xl),
                        children: const [
                          SizedBox(height: 180),
                          Center(child: AppLoader()),
                        ],
                      ),
                      error: (error, stackTrace) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.xl),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.22,
                          ),
                          Text(
                            'Unable to load messages.\n$error',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 0),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.18),
                    ),
                  ),
                  boxShadow: ShadowStyle.messageAura(
                    color: const Color(0xFFA78BFA),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.48,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.16),
                            width: 0.7,
                          ),
                          boxShadow: ShadowStyle.lightShadow(),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: _maxMessageChars,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                height: 1.18,
                                fontWeight: FontWeight.w500,
                              ),
                          decoration: InputDecoration(
                            hintText: 'Message $otherName',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.72,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton.filled(
                        onPressed: _isSending ? null : _sendMessage,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerHighest,
                          disabledForegroundColor: colorScheme.onSurfaceVariant,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const CircleBorder(),
                        ),
                        icon: _isSending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationAppBarTitle extends StatelessWidget {
  const _ConversationAppBarTitle({
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
  });

  final String name;
  final String? avatarUrl;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFBFDBFE),
                    Color(0xFFD8B4FE),
                    Color(0xFFFBCFE8),
                  ],
                ),
                boxShadow: ShadowStyle.messageAura(
                  color: const Color(0xFFA78BFA),
                ),
              ),
              child: AppUserAvatar(avatarUrl: avatarUrl, radius: 18),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.trim().isEmpty ? 'AI Builder' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
