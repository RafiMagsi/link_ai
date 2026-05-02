import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';

class SnowPostHeader extends StatelessWidget {
  const SnowPostHeader({
    super.key,
    required this.post,
    required this.avatarUrl,
    required this.authorName,
    required this.authorRole,
    this.onAvatarTap,
  });

  final PostModel post;
  final String? avatarUrl;
  final String authorName;
  final String authorRole;
  final VoidCallback? onAvatarTap;

  Color _accentColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFF7A756D),
      PostType.ship => const Color(0xFF4F8A12),
      PostType.ask => const Color(0xFF1D74C8),
      PostType.commentRepost => const Color(0xFF7A756D),
    };
  }

  Color _softColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFFF1EFE8),
      PostType.ship => const Color(0xFFEAF6DD),
      PostType.ask => const Color(0xFFE7F2FF),
      PostType.commentRepost => const Color(0xFFF1EFE8),
    };
  }

  String? _chipLabel(PostType type) {
    return switch (type) {
      PostType.thought => null,
      PostType.ship => 'Shipped',
      PostType.ask => 'Asking',
      PostType.commentRepost => null,
    };
  }

  IconData _chipIcon(PostType type) {
    return switch (type) {
      PostType.thought => Icons.auto_awesome_outlined,
      PostType.ship => Icons.rocket_launch_outlined,
      PostType.ask => Icons.help_outline_rounded,
      PostType.commentRepost => Icons.auto_awesome_outlined,
    };
  }

  String _initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '?';

    final words = clean.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }

    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }

  String _timeText(DateTime? createdAt) {
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
    final accent = _accentColor(post.postType);
    final softColor = _softColor(post.postType);
    final chipLabel = _chipLabel(post.postType);
    final displayName = authorName.trim().isEmpty ? 'AI Builder' : authorName.trim();
    final displayRole = authorRole.trim().isEmpty ? 'Builder' : authorRole.trim();
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: softColor,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasAvatar
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!.trim(),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _AvatarFallback(
                          initials: _initials(displayName),
                          color: accent,
                        ),
                        errorWidget: (_, __, ___) => _AvatarFallback(
                          initials: _initials(displayName),
                          color: accent,
                        ),
                      )
                    : _AvatarFallback(
                        initials: _initials(displayName),
                        color: accent,
                      ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.1,
                    ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.55),
                        fontSize: 11,
                        height: 1,
                      ),
                    ),
                  ),
                  Text(
                    _timeText(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (chipLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.10),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _chipIcon(post.postType),
                  size: 13,
                  color: accent,
                ),
                const SizedBox(width: 4),
                Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.color,
  });

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
