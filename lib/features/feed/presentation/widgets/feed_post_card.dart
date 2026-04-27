import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/post_model.dart';
import '../providers/post_providers.dart';

class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionState = ref.watch(postInteractionStateProvider(post.id));

    final liked = interactionState.asData?.value.liked ?? false;
    final reposted = interactionState.asData?.value.reposted ?? false;
    final saved = interactionState.asData?.value.saved ?? false;

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: post.authorName, avatarUrl: post.authorAvatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PostHeader(post: post),
                const SizedBox(height: 6),
                if (post.text.trim().isNotEmpty)
                  Text(
                    post.text,
                    style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 15.5,
                      height: 1.35,
                    ),
                  ),
                if (post.media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MediaGrid(mediaUrls: post.media.map((e) => e.url).toList()),
                ],
                const SizedBox(height: 10),
                _ActionRow(
                  post: post,
                  liked: liked,
                  reposted: reposted,
                  saved: saved,
                  onCommentTap: onCommentTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFF1E293B),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final PostModel post;

  String _timeText() {
    final createdAt = post.createdAt;

    if (createdAt == null) return 'now';

    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            post.authorName.isEmpty ? 'Unknown Builder' : post.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            post.authorRole.isEmpty ? 'AI Builder' : post.authorRole,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
        const SizedBox(width: 6),
        const Text('·', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(width: 6),
        Text(
          _timeText(),
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      ],
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.mediaUrls});

  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    final count = mediaUrls.length.clamp(0, 4);

    if (count == 1) {
      return _MediaTile(url: mediaUrls.first, height: 220);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return _MediaTile(url: mediaUrls[index]);
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.url, this.height});

  final String url;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
            ),
          );
        },
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({
    required this.post,
    required this.liked,
    required this.reposted,
    required this.saved,
    required this.onCommentTap,
  });

  final PostModel post;
  final bool liked;
  final bool reposted;
  final bool saved;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          active: false,
          count: post.commentsCount,
          onTap: onCommentTap,
        ),
        _ActionButton(
          icon: Icons.repeat,
          activeIcon: Icons.repeat,
          active: reposted,
          count: post.repostsCount,
          onTap: () =>
              ref.read(postControllerProvider.notifier).toggleRepost(post.id),
        ),
        _ActionButton(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          active: liked,
          count: post.likesCount,
          onTap: () =>
              ref.read(postControllerProvider.notifier).toggleLike(post.id),
        ),
        _ActionButton(
          icon: Icons.bookmark_border,
          activeIcon: Icons.bookmark,
          active: saved,
          count: post.savesCount,
          onTap: () =>
              ref.read(postControllerProvider.notifier).toggleSave(post.id),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                active ? activeIcon : icon,
                key: ValueKey<bool>(active),
                size: 19,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                count.toString(),
                key: ValueKey<int>(count),
                style: TextStyle(color: color, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
