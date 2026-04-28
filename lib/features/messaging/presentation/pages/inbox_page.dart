import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_ai/features/explore/presentation/widgets/shadow_style.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/messaging_providers.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(myInboxProvider);
    final currentUid = ref.watch(currentUserProvider)?.uid ?? '';

    Future<void> refreshInbox() async {
      ref.invalidate(myInboxProvider);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: refreshInbox,
        child: inboxState.when(
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.xxl,
                  AppSizes.lg,
                  AppSizes.xxxl,
                ),
                children: const [
                  _InboxEmptyState(),
                ],
              );
            }

            final unreadTotal = conversations.fold<int>(
              0,
              (total, conversation) =>
                  total + conversation.unreadCountFor(currentUid),
            );

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.md,
                AppSizes.lg,
                AppSizes.xxxl,
              ),
              itemCount: conversations.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _InboxHeader(
                    conversationsCount: conversations.length,
                    unreadCount: unreadTotal,
                  );
                }

                final conversation = conversations[index - 1];
                final otherName = conversation.getOtherName(currentUid);
                final otherAvatarUrl = conversation.getOtherAvatarUrl(currentUid);
                final unreadCount = conversation.unreadCountFor(currentUid);

                return _ConversationTile(
                  name: otherName,
                  avatarUrl: otherAvatarUrl,
                  lastMessage: conversation.lastMessage,
                  unreadCount: unreadCount,
                  onTap: () => context.push(
                    '/messages/${conversation.id}',
                    extra: conversation,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: AppLoader()),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.xxl,
              AppSizes.lg,
              AppSizes.xxxl,
            ),
            children: const [
              _InboxErrorState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({
    required this.conversationsCount,
    required this.unreadCount,
  });

  final int conversationsCount;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
            width: 0.7,
          ),
          boxShadow: ShadowStyle.lightShadow(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$conversationsCount conversations',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                _UnreadBadge(
                  label: unreadCount > 99 ? '99+' : '$unreadCount',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUnread = unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFFA78BFA).withValues(alpha: 0.16)
                : const Color(0xFFA78BFA).withValues(alpha: 0.07),
            width: 0.7,
          ),
          boxShadow: ShadowStyle.lightShadow(
            color: hasUnread ? const Color(0xFFA78BFA) : null,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AppUserAvatar(
                          avatarUrl: avatarUrl,
                          radius: 28,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: -1,
                            bottom: -1,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.trim().isEmpty ? 'AI Builder' : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: hasUnread
                                        ? FontWeight.w900
                                        : FontWeight.w800,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              if (hasUnread)
                                _UnreadBadge(
                                  label: unreadCount > 99 ? '99+' : '$unreadCount',
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            lastMessage.trim().isEmpty
                                ? 'No messages yet'
                                : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: hasUnread
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  height: 1.25,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF60A5FA),
            Color(0xFFA78BFA),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF312E81),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
          width: 0.7,
        ),
        boxShadow: ShadowStyle.lightShadow(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
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
                Icons.mail_outline_rounded,
                color: Color(0xFF312E81),
                size: 28,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Open a builder profile and start a useful conversation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxErrorState extends StatelessWidget {
  const _InboxErrorState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
          width: 0.7,
        ),
        boxShadow: ShadowStyle.lightShadow(),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 38),
            SizedBox(height: AppSizes.md),
            Text(
              'Unable to load messages',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
